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

        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        frame = superview!.frame
        isHidden = true

        let iconLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        iconLabel.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        iconLabel.center = center
        iconLabel.font = .systemFont(ofSize: 14)
        iconLabel.layer.backgroundColor = UIColor.gray.withAlphaComponent(0.5).cgColor
        iconLabel.layer.cornerRadius = 10
        iconLabel.layer.masksToBounds = true
        iconLabel.text = "!"
        iconLabel.textAlignment = .center
        iconLabel.textColor = .white
        addSubview(iconLabel)
    }

    func show() {
        isHidden = false
    }

    func hide() {
        isHidden = true
    }
}
