//
//  TransferService.swift
//  Mock POS
//
//  Created by Milan Djordjevic on 01/11/2022.
//

import CoreBluetooth
import Foundation

struct TransferService {
    static let serviceUUID = CBUUID(string: "CAB1B028-2243-4F2C-A2F1-3BE5AD51AD61")
    static let characteristicUUID = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
}
