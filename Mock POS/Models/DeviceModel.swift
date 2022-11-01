//
//  DeviceModel.swift
//  Mock POS
//
//  Created by Milan Djordjevic on 25/10/2022.
//

import Foundation

struct DeviceModel: Codable {
    let name: String?
    let identifier: UUID
    let state: Int
}
