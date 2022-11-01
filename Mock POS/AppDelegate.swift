//
//  AppDelegate.swift
//  Mock POS
//
//  Created by Milan Djordjevic on 24/10/2022.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.makeKeyAndVisible()
        let navigationController = UINavigationController()
        let start = HomeCoordinator(presenter: navigationController)
        window?.rootViewController = navigationController
        start.start()
        return true
    }
}

