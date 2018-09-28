//
//  AppDelegate.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import AlamofireImage
import Regex
import SnapKit
import SwiftDate
import UITextView_Placeholder

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        application.shortcutItems = [
            UIApplicationShortcutItem(type: "compose", localizedTitle: "发帖", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(type: .compose), userInfo: nil),
        ]

        GAI.sharedInstance().logger.logLevel = .error
        GAI.sharedInstance().trackUncaughtExceptions = true
        GAI.sharedInstance().tracker(withTrackingId: Bundle.main.infoDictionary?["GoogleAnalyticsTrackingId"] as? String ?? "")

        SwiftDate.defaultRegion = Region(calendar: Calendars.gregorian, zone: Zones.asiaShanghai, locale: Locales.chinese)

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = SplitViewController()
        window?.tintColor = UIColor(named: "TintColor")
        window?.makeKeyAndVisible()

        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            if let url = userActivity.webpageURL, let id = "^/topics/(\\d+)$".r?.findFirst(in: url.path)?.group(at: 1) {
                let topicController = TopicController()
                topicController.topic = try? Topic(json: [:])
                topicController.topic?.id = Int(id)
                window?.rootViewController?.showDetailViewController(UINavigationController(rootViewController: topicController), sender: nil)
                return true
            }
        }
        return false
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
        case "compose":
            let composeController = ComposeController()
            composeController.topic = try? Topic(json: [:])
            window?.rootViewController?.showDetailViewController(UINavigationController(rootViewController: composeController), sender: nil)
        default:
            break
        }
    }
}
