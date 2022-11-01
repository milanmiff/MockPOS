//
//  HomeCoordinator.swift
//  Mock POS
//
//  Created by Milan Djordjevic on 26/10/2022.
//

import UIKit

protocol HomeCoordinating: Coordinating { }

final class HomeCoordinator: HomeCoordinating {
    private weak var presenter: UINavigationController?
    
    init(presenter: UINavigationController) {
        self.presenter = presenter
    }
    
    func start() {
        let viewModel = HomeViewModel(coordinator: self)
        let viewController = HomeViewController(viewModel: viewModel)
        presenter?.pushViewController(viewController, animated: true)
    }
}
