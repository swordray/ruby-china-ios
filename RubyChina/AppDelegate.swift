//
//  AppDelegate.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/19/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import AFNetworking
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if #available(iOS 9.1, *) {
            application.shortcutItems = [
                UIApplicationShortcutItem(type: "topics", localizedTitle: "社区", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(type: .Home), userInfo: nil),
                UIApplicationShortcutItem(type: "compose", localizedTitle: "发帖", localizedSubtitle: nil, icon: UIApplicationShortcutIcon(type: .Compose), userInfo: nil),
            ]
        }

        AFNetworkActivityIndicatorManager.sharedManager().enabled = true

        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = SplitViewController()
        window?.tintColor = Helper.tintColor
        window?.makeKeyAndVisible()

        return true
    }

    @available(iOS 9.0, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        guard let splitViewController = window?.rootViewController as? SplitViewController else { return }
        switch shortcutItem.type {
        case "topics":
            guard let navigationController = splitViewController.viewControllers.first as? UINavigationController else { return }
            navigationController.popToRootViewControllerAnimated(true)
        case "compose":
            splitViewController.showDetailViewController(UINavigationController(rootViewController: ComposeController()), sender: nil)
        default: 0
        }
    }
}
