//
//  Helper.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/22/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import DateTools
import SwiftyJSON
import UIKit

class Helper {
    class var backgroundColor: UIColor {
        return UIColor(red: 239/255.0, green: 239/255.0, blue: 244/255.0, alpha: 1)
    }

    class var baseURL: NSURL {
        return NSURL(string: "http://ruby-china.secipin.com")!
    }

    class var googleAnalyticsId: String {
        return "UA-8885744-9"
    }

    class var tintColor: UIColor {
        return UIColor(red: 155/255.0, green: 17/255.0, blue: 30/255.0, alpha: 1)
    }

    class func blankImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }

    class func log(object: AnyObject?) {
        NSLog("\(object)", "")
    }

    class func log(object: CGRect?) {
        NSLog("\(object)", "")
    }

    class func log(object: JSON?) {
        NSLog("\(object)", "")
    }

    class func log(object: NSObject?) {
        NSLog("\(object)", "")
    }

    class func signIn(viewController: UIViewController?) {
        let signInController = SignInController()
        signInController.viewController = viewController
        let navigationController = UINavigationController(rootViewController: signInController)
        navigationController.modalPresentationStyle = .FormSheet
        viewController?.presentViewController(navigationController, animated: true, completion: nil)
    }

    class func timeAgoSinceNow(original: String?) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return dateFormatter.dateFromString(original ?? "")?.timeAgoSinceNow() ?? ""
    }

    class func trackView(object: AnyObject) {
        GAI.sharedInstance().logger.logLevel = .Error
        GAI.sharedInstance().trackUncaughtExceptions = true
        GAI.sharedInstance().trackerWithTrackingId(Helper.googleAnalyticsId)
        GAI.sharedInstance().defaultTracker.send([kGAIHitType: "appview", kGAIScreenName: String(NSStringFromClass(object.classForCoder).characters.split(".").last!)])
    }
}
