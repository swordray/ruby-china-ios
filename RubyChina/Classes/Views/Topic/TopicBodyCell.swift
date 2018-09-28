//
//  TopicBodyCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit

class TopicBodyCell: TopicWebCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.equalToSuperview().offset(UIFontMetrics.default.scaledValue(for: 13.5))
            make.bottom.equalToSuperview().offset(UIFontMetrics.default.scaledValue(for: -13.5))
        }
    }
}
