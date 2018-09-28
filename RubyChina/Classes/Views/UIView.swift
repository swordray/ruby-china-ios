//
//  UIView.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit

extension UIResponder {

    internal func next<T>(of type: T.Type) -> T? {
        return next as? T ?? next?.next(of: type)
    }
}

extension UIView {

    internal var viewController: ViewController? {
        return next(of: ViewController.self)
    }
}
