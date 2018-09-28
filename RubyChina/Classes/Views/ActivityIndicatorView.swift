//
//  ActivityIndicatorView.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit

class ActivityIndicatorView: UIActivityIndicatorView {

    init() {
        super.init(style: .gray)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if let superview = self.superview {
            snp.makeConstraints { $0.center.equalTo(superview.safeAreaLayoutGuide) }
        }
    }
}
