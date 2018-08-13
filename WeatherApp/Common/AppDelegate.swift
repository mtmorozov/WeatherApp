//
//  AppDelegate.swift
//  WeatherApp
//
//  Created by Dmitrii Morozov on 25/01/2018.
//  Copyright © 2018 Dmitrii Morozov. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        ConnectionController.shared.startConnectionTracking()
        
        return true
    }
}
