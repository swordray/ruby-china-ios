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
        AFNetworkActivityIndicatorManager.sharedManager().enabled = true

        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = SplitViewController()
        window?.tintColor = Helper.tintColor
        window?.makeKeyAndVisible()

        return true
    }
}
