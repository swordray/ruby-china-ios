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

        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        font = .systemFont(ofSize: 28)
        frame = superview!.frame
        isHidden = true
        textAlignment = .center
        textColor = .gray
    }

    func show() {
        isHidden = false
    }

    func hide() {
        isHidden = true
    }
}
