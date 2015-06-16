//
//  Defaults.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/29/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import UIKit

class Defaults {
    class var userId: Int? {
        get { return NSUserDefaults.standardUserDefaults().valueForKey("userId") as? Int }
        set (value) { NSUserDefaults.standardUserDefaults().setValue(value, forKey: "userId") }
    }
}
