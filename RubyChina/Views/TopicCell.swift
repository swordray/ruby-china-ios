//
//  TopicCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/22/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import SwiftyJSON
import UIKit

class TopicCell: UITableViewCell {

    var topic: JSON = [:]


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)

        accessoryType = .DisclosureIndicator

        textLabel?.numberOfLines = 4

        detailTextLabel?.font = .systemFontOfSize(14)
        detailTextLabel?.textColor = .lightGrayColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        textLabel?.frame.origin.y = 11.5
        textLabel?.text = topic["title"].string
        textLabel?.frame.size.height = textLabel!.textRectForBounds(textLabel!.frame, limitedToNumberOfLines: 3).height

        detailTextLabel?.frame.origin.y = 11.5 + textLabel!.frame.height + 6.5
        detailTextLabel?.text = "[" + topic["node_name"].stringValue + "] · " + topic["user"]["login"].stringValue + " · " + Helper.timeAgoSinceNow(topic["replied_at"].string ?? topic["created_at"].string) + (topic["replies_count"].intValue > 0 ? " · " + topic["replies_count"].stringValue + " ↵" : "")
    }
}
