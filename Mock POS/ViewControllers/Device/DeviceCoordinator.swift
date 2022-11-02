//
//  DeviceCoordinator.swift
//  Mock POS
//
//  Created by Milan Djordjevic on 02/11/2022.
//

import UIKit

protocol DeviceCoordinating: Coordinating { }

final class DeviceCoordinator: DeviceCoordinating {
    private weak var presenter: UINavigationController?
    
    init(presenter: UINavigationController) {
        self.presenter = presenter
    }
    
    func start() {
        let viewModel = DeviceViewModel(coordinator: self)
        viewModel.textToSend = "Hello 👋"
        let viewController = DeviceViewController(viewModel: viewModel)
        presenter?.pushViewController(viewController, animated: true)
    }
}
