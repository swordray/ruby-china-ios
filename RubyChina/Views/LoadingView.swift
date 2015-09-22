//
//  LoadingView.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/22/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import UIKit

class LoadingView: UIActivityIndicatorView {

    var refreshing: Bool {
        get { return !hidden }
    }


    override func didMoveToSuperview() {
        if superview == nil { return }

        activityIndicatorViewStyle = .Gray
        autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleTopMargin, .FlexibleBottomMargin]
        center = superview!.center
        hidesWhenStopped = true
    }

    func show() {
        startAnimating()
    }

    func hide() {
        stopAnimating()
    }
}
