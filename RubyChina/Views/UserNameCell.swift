//
//  UserNameCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/29/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import SDWebImage
import SwiftyJSON
import UIKit

class UserNameCell: UITableViewCell {

    var user: JSON = [:]


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)

        accessoryType = .DisclosureIndicator

        imageView?.layer.cornerRadius = 3
        imageView?.layer.masksToBounds = true

        detailTextLabel?.font = .systemFontOfSize(14)
        detailTextLabel?.textColor = .lightGrayColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView?.frame = CGRect(x: separatorInset.left, y: 10, width: 44, height: 44)
        imageView?.sd_setImageWithURL(NSURL(string: user["avatar_url"].stringValue)!, placeholderImage: Helper.blankImage(imageView!.frame.size))

        textLabel?.frame = CGRect(x: separatorInset.left * 2 + 44, y: 10, width: frame.width - separatorInset.left * 3 - 44, height: textLabel!.frame.height)
        textLabel?.text = user["login"].string

        detailTextLabel?.frame = CGRect(x: separatorInset.left * 2 + 44, y: 10
            + textLabel!.frame.height + 6, width: bounds.width - separatorInset.left * 3 - 44, height: detailTextLabel!.frame.height)
        detailTextLabel?.text = user["name"].stringValue != "" ? user["name"].string : user["login"].string
    }
}
