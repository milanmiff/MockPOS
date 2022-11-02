//
//  DeviceViewModel.swift
//  Mock POS
//
//  Created by Milan Djordjevic on 01/11/2022.
//

import CoreBluetooth
import Foundation

protocol DeviceViewModeling {
    var viewDelegate: DeviceViewControllerDelegating? { get set }
    var textToSend: String? { get set }
    func stopAdvertising()
    func sendData()
}

final class DeviceViewModel: NSObject, DeviceViewModeling {
    weak var viewDelegate: DeviceViewControllerDelegating?
    var textToSend: String?
    private var peripheralManager: CBPeripheralManager!
    private var isAdvertising = true
    private var transferCharacteristic: CBMutableCharacteristic?
    private var connectedCentral: CBCentral?
    private var dataToSend = Data()
    private var sendDataIndex: Int = 0
    private var isSendingEOM = false
    
    init(coordinator: Coordinating) {
        super.init()
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }
    
    func stopAdvertising() {
        peripheralManager.stopAdvertising()
    }
    
    private func setupPeripheral() {
        let characteristic = CBMutableCharacteristic(type: TransferService.characteristicUUID,
                                                     properties: [.notify, .writeWithoutResponse],
                                                     value: nil,
                                                     permissions: [.readable, .writeable])
        let transferService = CBMutableService(type: TransferService.serviceUUID, primary: true)
        transferService.characteristics = [characteristic]
        peripheralManager.add(transferService)
        transferCharacteristic = characteristic
        peripheralManager.startAdvertising(([CBAdvertisementDataServiceUUIDsKey: [TransferService.serviceUUID], CBAdvertisementDataLocalNameKey: "BLEphone"]))
    }
    
    
    // TODO: - Fix this
    func sendData() {
        guard let transferCharacteristic = transferCharacteristic else { return }
        if isSendingEOM {
            let didSend = peripheralManager.updateValue("EOM".data(using: .utf8)!, for: transferCharacteristic, onSubscribedCentrals: nil)
            if didSend {
                isSendingEOM = false
                Log.info("Sent: EOM")
            }
            return
        }
        
        if sendDataIndex >= dataToSend.count { return }
        
        var didSend = true
        while didSend {
            var amountToSend = dataToSend.count - sendDataIndex
            if let mtu = connectedCentral?.maximumUpdateValueLength {
                amountToSend = min(amountToSend, mtu)
            }
            
            let chunk = dataToSend.subdata(in: sendDataIndex..<(sendDataIndex + amountToSend))
            didSend = peripheralManager.updateValue(chunk, for: transferCharacteristic, onSubscribedCentrals: nil)
            
            if !didSend { return }
            
            let stringFromData = String(data: chunk, encoding: .utf8)
            Log.info("Sent \(chunk.count) bytes: \(String(describing: stringFromData))")
            sendDataIndex += amountToSend
            if sendDataIndex >= dataToSend.count {
                isSendingEOM = true
                let eomSent = peripheralManager.updateValue("EOM".data(using: .utf8)!,
                                                            for: transferCharacteristic,
                                                            onSubscribedCentrals: nil)
                
                if eomSent {
                    isSendingEOM = false
                    Log.info("Sent: EOM")
                }
                return
            }
        }
    }
}

extension DeviceViewModel: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        isAdvertising = peripheral.state == .poweredOn
        switch peripheral.state {
        case .poweredOn:
            Log.info("peripheral is powered on")
            setupPeripheral()
        case .poweredOff:
            Log.info("peripheral is not powered on")
            return
        case .resetting:
            Log.info("peripheral is resetting")
            return
        case .unauthorized:
            Log.warning("You are not authorized to use Bluetooth")
            return
        case .unknown:
            Log.warning("peripheral state is unknown")
            return
        case .unsupported:
            Log.warning("Bluetooth is not supported on this device")
            return
        @unknown default:
            Log.warning("A previously unknown peripheral manager state occurred")
            return
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard let textToSend = textToSend else { return }
        Log.info("Central subscribed to characteristic")
        dataToSend = textToSend.data(using: .utf8)!
        sendDataIndex = 0
        connectedCentral = central
        sendData()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        Log.info("Central unsubscribed from characteristic")
        connectedCentral = nil
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        sendData()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        Log.info("Received read request bytes: \(request.debugDescription)")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for aRequest in requests {
            guard let requestValue = aRequest.value,
                  let stringFromData = String(data: requestValue, encoding: .utf8) else {
                continue
            }
            
            Log.info("Received write request of \(requestValue.count) bytes: \(stringFromData)")
            // TODO: - send string trough delegate here `stringFromData`
        }
    }
}
