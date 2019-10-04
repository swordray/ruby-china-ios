//
//  AppDelegate.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import Firebase
import Regex
import SnapKit
import SwiftDate
import UITextView_Placeholder

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()

        SwiftDate.defaultRegion = Region(calendar: Calendars.gregorian, zone: Zones.asiaShanghai, locale: Locales.chinese)

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: TopicsController())
        window?.tintColor = UIColor(named: "TintColor")
        window?.makeKeyAndVisible()

        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL, let id = "^/topics/(\\d+)$".r?.findFirst(in: url.path)?.group(at: 1) {
                let topicController = TopicController()
                topicController.topic = try? Topic(json: ["id": Int(id)])
                (window?.rootViewController as? UINavigationController)?.pushViewController(topicController, animated: false)
                return true
            }
        }
        return false
    }
}
