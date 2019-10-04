//
//  TopicReplyDeletedCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit

class TopicReplyDeletedCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let size = CGSize(width: 44, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        imageView?.image = image

        selectionStyle = .none

        textLabel?.attributedText = NSAttributedString(string: "已删除", attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
        textLabel?.font = .preferredFont(forTextStyle: .subheadline)
        textLabel?.textAlignment = .center
        textLabel?.textColor = .tertiaryLabel
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
