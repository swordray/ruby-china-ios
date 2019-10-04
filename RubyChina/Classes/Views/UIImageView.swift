//
//  UIImageView.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 6/14/19.
//  Copyright © 2019 Jianqiu Xiao. All rights reserved.
//

import AlamofireImage

extension UIImageView {

    internal func setImage(withURL url: URL?) {
        if let url = url {
            af_setImage(withURL: url, placeholderImage: UIImage())
        } else {
            image = nil
        }
    }
}
