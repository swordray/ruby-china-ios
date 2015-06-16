//
//  EmptyView.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/22/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import UIKit

class EmptyView: UILabel {

    override func didMoveToSuperview() {
        if superview == nil { return }

        autoresizingMask = .FlexibleWidth | .FlexibleHeight
        font = .systemFontOfSize(28)
        frame = superview!.frame
        hidden = true
        textAlignment = .Center
        textColor = .grayColor()
    }

    func show() {
        hidden = false
    }

    func hide() {
        hidden = true
    }
}
