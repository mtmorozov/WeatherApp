//
//  ConnectionController.swift
//  WeatherApp
//
//  Created by Dmitrii Morozov on 29/01/2018.
//  Copyright © 2018 Dmitrii Morozov. All rights reserved.
//

import Reachability

final class ConnectionController {
    /// Singleton
    static let shared = ConnectionController()
    
    var isOnline: Bool {
        if let reachability = reachability {
            return reachability.connection != .none
        }
        else {
            return false
        }
    }
    
    /// Reachability
    let reachability: Reachability? = Reachability()
    
    /// Initializer
    private init() {
        setupReachability()
    }
}

// MARK:- Setup
fileprivate extension ConnectionController {
    func setupReachability() {
        reachability?.whenReachable   = handleConnectivityEvent
        reachability?.whenUnreachable = handleConnectivityEvent
    }
    
    private func handleConnectivityEvent(_ reachability: Reachability) {
        NotificationCenter.default.post(name: Notification.Name(Notifications.offlineNotification), object: nil)
    }
}

// MARK:- Methods
extension ConnectionController {
    func startConnectionTracking() {
        do {
            try reachability?.startNotifier()
        }
        catch {
            print("Unable to start notifier")
        }
    }
    
    func stopConnectionTracking() {
        reachability?.stopNotifier()
    }
}
