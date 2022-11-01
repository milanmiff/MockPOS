//
//  HomeViewModel.swift
//  Mock POS
//
//  Created by Milan Djordjevic on 26/10/2022.
//

import CoreBluetooth
import Foundation

protocol HomeViewModeling {
    var viewDelegate: HomeViewControllerDelegating? { get set }
    func sendDataToTerminal(payload: String)
}

final class HomeViewModel: NSObject, HomeViewModeling {
    weak var viewDelegate: HomeViewControllerDelegating?
    private let coordinator: HomeCoordinating
    private var centralManager: CBCentralManager!
    private var discoveredDevice: CBPeripheral?
    private var transferCharacteristic: CBCharacteristic?
    private var writeIterationsComplete = 0
    private var connectionIterationsComplete = 0
    private let defaultIterations = 10
    private var data = Data()
    
    init(coordinator: HomeCoordinating) {
        self.coordinator = coordinator
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    func sendDataToTerminal(payload: String) {
        
    }
    
    private func cleanUp() {
        guard let discoveredDevice = discoveredDevice,
              case .connected = discoveredDevice.state else { return }
        for service in (discoveredDevice.services ?? [] as [CBService]) {
            for characteristic in (service.characteristics ?? [] as [CBCharacteristic]) {
                if characteristic.uuid == TransferService.characteristicUUID && characteristic.isNotifying {
                    self.discoveredDevice?.setNotifyValue(false, for: characteristic)
                }
            }
        }
        centralManager.cancelPeripheralConnection(discoveredDevice)
    }
    
    private func retrieveDevice() {
        let connectedDevices: [CBPeripheral] = (centralManager.retrieveConnectedPeripherals(withServices: [TransferService.serviceUUID]))
        Log.info("Found connected devices with transfer service: \(connectedDevices)")
        
        if let connectedDevice = connectedDevices.last {
            Log.info("Connecting to device \(connectedDevice)")
            discoveredDevice = connectedDevice
            centralManager.connect(connectedDevice)
        } else {
            centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    private func writeData() {
        guard let discoveredDevice = discoveredDevice,
              let transferCharacteristic = transferCharacteristic else { return }
        while writeIterationsComplete < defaultIterations && discoveredDevice.canSendWriteWithoutResponse {
            let mtu = discoveredDevice.maximumWriteValueLength (for: .withoutResponse)
            var rawPacket = [UInt8]()
            
            let bytesToCopy: size_t = min(mtu, data.count)
            data.copyBytes(to: &rawPacket, count: bytesToCopy)
            let packetData = Data(bytes: &rawPacket, count: bytesToCopy)
            
            let stringFromData = String(data: packetData, encoding: .utf8)
            Log.info("Writing \(bytesToCopy) bytes: \(String(describing: stringFromData))")
            discoveredDevice.writeValue(packetData, for: transferCharacteristic, type: .withoutResponse)
            writeIterationsComplete += 1
        }
        
        if writeIterationsComplete == defaultIterations {
            discoveredDevice.setNotifyValue(false, for: transferCharacteristic)
        }
    }
}

// MARK: - CB peripherial/device delegate
extension HomeViewModel: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service in invalidatedServices where service.uuid == TransferService.serviceUUID {
            Log.info("Transfer service is invalidated - rediscover services")
            peripheral.discoverServices([TransferService.serviceUUID])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            Log.error("Error discovering services: \(error.localizedDescription)")
            cleanUp()
            return
        }
        
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics([TransferService.characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            Log.error("Error discovering characteristics: \(error.localizedDescription)")
            cleanUp()
            return
        }
        
        guard let serviceCharacteristics = service.characteristics else { return }
        for characteristic in serviceCharacteristics where characteristic.uuid == TransferService.characteristicUUID {
            transferCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            Log.error("Error discovering characteristics: \(error.localizedDescription)")
            cleanUp()
            return
        }
        
        guard let characteristicData = characteristic.value,
              let stringFromData = String(data: characteristicData, encoding: .utf8) else { return }
        Log.info("Received \(characteristicData.count) bytes: \(stringFromData)")
        if stringFromData == "EOM" {
            DispatchQueue.main.async() { [weak self] in
                guard let self = self else { return }
                self.viewDelegate?.updateField(with: String(data: self.data, encoding: .utf8)!)
            }
            writeData()
        } else {
            data.append(characteristicData)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            Log.error("Error changing notification state: \(error.localizedDescription)")
            cleanUp()
            return
        }
        
        guard characteristic.uuid == TransferService.characteristicUUID else { return }
        
        if characteristic.isNotifying {
            // Notification has started
            Log.info("Notification started on \(characteristic)")
        } else {
            Log.info("Notification stopped on \(characteristic) Disconnecting...")
            cleanUp()
        }
        
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        Log.info("Device is ready, send data")
        writeData()
    }
}


// MARK: - CB Central manager
extension HomeViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unsupported: Log.info("Unsupported")
        case .poweredOn: Log.info("Power on")
        case .poweredOff: Log.info("Power off")
        case .unauthorized: Log.info("Unauthorized")
        case .resetting: Log.info("Connection is lost")
        case .unknown: Log.info("Unknown")
        @unknown default: Log.error("Usualy fatal error :)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard RSSI.intValue >= -50 else {
            Log.warning("Not in range \(RSSI.intValue)")
            return
        }
        
        if discoveredDevice != peripheral {
            discoveredDevice = peripheral
            Log.info("Connect to device \(peripheral)")
            centralManager.connect(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Log.info("Failed to connect to \(peripheral) with error: \(String(describing: error))")
        cleanUp()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Log.info("Device Connected")
        centralManager.stopScan()
        Log.info("Stopped scanning")
        connectionIterationsComplete += 1
        writeIterationsComplete = 0
        data.removeAll(keepingCapacity: false)
        peripheral.delegate = self
        peripheral.discoverServices([TransferService.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Log.info("Device is disconnected")
        discoveredDevice = nil
        if connectionIterationsComplete < defaultIterations {
            retrieveDevice()
        } else {
            Log.info("Connection iterations done")
        }
    }
}
