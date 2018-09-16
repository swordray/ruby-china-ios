//
//  UserNameCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/29/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import SwiftyJSON
import UIKit

class UserNameCell: UITableViewCell {

    var user: JSON = [:]


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        imageView?.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        imageView?.layer.cornerRadius = 22
        imageView?.layer.masksToBounds = true

        detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        detailTextLabel?.textColor = .lightGray
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView?.frame = CGRect(x: separatorInset.left, y: 11.5, width: 44, height: 44)
        if let url = URL(string: user["avatar_url"].stringValue) { imageView?.setImageWith(url, placeholderImage: Helper.blankImage(imageView!.frame.size)) }

        textLabel?.frame = CGRect(x: separatorInset.left * 2 + 44, y: 11.5, width: frame.width - separatorInset.left * 3 - 44, height: textLabel!.frame.height)
        textLabel?.text = user["login"].string

        detailTextLabel?.frame = CGRect(x: separatorInset.left * 2 + 44, y: 11.5
            + textLabel!.frame.height + 5, width: bounds.width - separatorInset.left * 3 - 44, height: detailTextLabel!.frame.height)
        detailTextLabel?.text = user["name"].stringValue != "" ? user["name"].string : user["login"].string
    }
}
