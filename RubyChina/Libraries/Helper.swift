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

    class var baseURL: URL {
        return URL(string: "http://ruby-china.secipin.com")!
    }

    class var googleAnalyticsId: String {
        return "UA-8885744-9"
    }

    class var tintColor: UIColor {
        return UIColor(red: 155/255.0, green: 17/255.0, blue: 30/255.0, alpha: 1)
    }

    class func blankImage(_ size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }

    class func log(_ object: AnyObject?) {
        NSLog("\(object)", "")
    }

    class func log(_ object: CGRect?) {
        NSLog("\(object)", "")
    }

    class func log(_ object: JSON?) {
        NSLog("\(object)", "")
    }

    class func log(_ object: NSObject?) {
        NSLog("\(object)", "")
    }

    class func timeAgoSinceNow(_ original: String?) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return (dateFormatter.date(from: original ?? "") as NSDate?)?.timeAgoSinceNow() ?? ""
    }

    class func trackView(_ object: AnyObject) {
        GAI.sharedInstance().logger.logLevel = .error
        GAI.sharedInstance().trackUncaughtExceptions = true
        GAI.sharedInstance().tracker(withTrackingId: Helper.googleAnalyticsId)
        GAI.sharedInstance().defaultTracker.send([kGAIHitType: "appview", kGAIScreenName: String(NSStringFromClass(object.classForCoder).characters.split(separator: ".").last!)])
    }
}
