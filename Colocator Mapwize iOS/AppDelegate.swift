//
//  AppDelegate.swift
//  Colocator Mapwize iOS
//
//  Created by TCode on 21/02/2020.
//  Copyright © 2020 CrowdConnected. All rights reserved.
//

import UIKit
import CCLocation
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared.enable = true
        
        guard let clientKey = UserDefaults.standard.value(forKey: kClientKeyStorageKey) as? String else {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { authorized, error in }
            UIApplication.shared.registerForRemoteNotifications()
            return true
        }
        
        let serverIndex = UserDefaults.standard.value(forKey: kServerIndexStorageKey) as? Int ?? 0
        if serverIndex == 0 {
            CCLocation.sharedInstance.start(apiKey: clientKey, urlString: kCCUrlStaging)
        } else if serverIndex == 1 {
            CCLocation.sharedInstance.start(apiKey: clientKey)
        } else {
            CCLocation.sharedInstance.start(apiKey: clientKey, urlString: kCCUrlDevelopment)
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { authorized, error in }
        UIApplication.shared.registerForRemoteNotifications()
        
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // For CCLocation messaging feature, send device token to the library as an alias
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        CCLocation.sharedInstance.addAlias(key: "apns_user_id", value: tokenString)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // CCLocation can send Silent Push Notifications to wake up the library when needed; check the source of the SPN and pass it to the library
        if userInfo["source"] as? String == "colocator" {
            guard let clientKey = UserDefaults.standard.value(forKey: kClientKeyStorageKey) as? String else { return }
        
            CCLocation.sharedInstance.receivedSilentNotification(userInfo: userInfo, clientKey: clientKey) { isNewData in
                if isNewData {
                    completionHandler(.newData)
                } else {
                    completionHandler(.noData)
                }
            }
        }
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // At background refresh, the CCLocation library should be notified to update its state
        guard let clientKey = UserDefaults.standard.value(forKey: kClientKeyStorageKey) as? String else { return }
        
        CCLocation.sharedInstance.updateLibraryBasedOnClientStatus(clientKey: clientKey) { success in
            if success {
                completionHandler(.newData)
            } else {
                completionHandler(.noData)
            }
        }
    }
}

