//
//  FailureView.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/22/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import UIKit

class FailureView: UIView {

    override func didMoveToSuperview() {
        if superview == nil { return }

        autoresizingMask = .FlexibleWidth | .FlexibleHeight
        frame = superview!.frame
        hidden = true

        let iconLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        iconLabel.autoresizingMask = .FlexibleLeftMargin | .FlexibleRightMargin | .FlexibleTopMargin | .FlexibleBottomMargin
        iconLabel.center = center
        iconLabel.font = .systemFontOfSize(16)
        iconLabel.layer.backgroundColor = UIColor.grayColor().colorWithAlphaComponent(0.5).CGColor
        iconLabel.layer.cornerRadius = 12
        iconLabel.layer.masksToBounds = true
        iconLabel.text = "!"
        iconLabel.textAlignment = .Center
        iconLabel.textColor = .whiteColor()
        addSubview(iconLabel)
    }

    func show() {
        hidden = false
    }

    func hide() {
        hidden = true
    }
}
