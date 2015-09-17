//
//  TopicTitleCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/28/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import AFNetworking
import MBProgressHUD
import MGSwipeTableCell
import SDWebImage
import SwiftyJSON
import UIKit

class TopicTitleCell: MGSwipeTableCell {

    var deleteButton = MGSwipeButton()
    var editButton = MGSwipeButton()
    var topic: JSON = [:]
    weak var topicController: TopicController?


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)

        selectionStyle = .None

        imageView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("user")))
        imageView?.layer.cornerRadius = 3
        imageView?.layer.masksToBounds = true
        imageView?.userInteractionEnabled = true

        textLabel?.numberOfLines = 4

        detailTextLabel?.font = .systemFontOfSize(14)
        detailTextLabel?.textColor = .lightGrayColor()

        editButton.backgroundColor = UIColor(red: 199/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1)
        editButton.buttonWidth = 66
        editButton.callback = { (_) in
            let composeController = ComposeController()
            composeController.topic = self.topic
            self.topicController?.navigationController?.pushViewController(composeController, animated: true)
            return true
        }
        editButton.setTitle("编辑", forState: .Normal)

        deleteButton.backgroundColor = UIColor(red: 255/255.0, green: 59/255.0, blue: 48/255.0, alpha: 1)
        deleteButton.buttonWidth = 66
        deleteButton.callback = { (_) in
            let alertController = UIAlertController(title: "确定删除吗？", message: nil, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "删除", style: .Default, handler: { (_) in
                let progressHUD = MBProgressHUD.showHUDAddedTo(self.topicController!.view, animated: false)
                AFHTTPRequestOperationManager(baseURL: Helper.baseURL).DELETE("/topics/" + self.topic["id"].stringValue + ".json", parameters: nil, success: { (operation, responseObject) in
                    progressHUD.hide(false)
                    if self.topicController?.navigationController?.viewControllers.count > 1 {
                        self.topicController?.navigationController?.popViewControllerAnimated(true)
                    } else if self.topicController?.navigationController?.navigationController != nil {
                        self.topicController?.navigationController?.navigationController?.popViewControllerAnimated(true)
                    } else {
                        self.topicController?.splitViewController?.showDetailViewController(UIViewController(), sender: self)
                    }
                }) { (operation, error) in
                    if operation.response != nil && operation.response.statusCode == 401 { progressHUD.hide(false); Helper.signIn(self.topicController); return }
                    progressHUD.labelText = "网络错误"
                    progressHUD.mode = .Text
                    progressHUD.hide(true, afterDelay: 2)
                }
            }))
            self.topicController?.navigationController?.presentViewController(alertController, animated: true, completion: nil)
            return false
        }
        deleteButton.setTitle("删除", forState: .Normal)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        separatorInset.left = topicController!.tableView.separatorInset.left

        imageView?.frame = CGRect(x: separatorInset.left, y: 10, width: 44, height: 44)
        imageView?.sd_setImageWithURL(NSURL(string: topic["user"]["avatar_url"].stringValue)!, placeholderImage: Helper.blankImage(imageView!.frame.size))

        textLabel?.frame = CGRect(x: separatorInset.left * 2 + 44, y: 10, width: frame.width - separatorInset.left * 3 - 44, height: 100)
        textLabel?.text = topic["title"].string
        textLabel?.frame.size.height = textLabel!.textRectForBounds(textLabel!.frame, limitedToNumberOfLines: textLabel!.numberOfLines).height

        detailTextLabel?.frame = CGRect(x: separatorInset.left * 2 + 44, y: 10 + textLabel!.frame.height + 6, width: bounds.width - separatorInset.left * 3 - 44, height: detailTextLabel!.frame.height)
        detailTextLabel?.text = "[" + topic["node_name"].stringValue + "] · " + topic["user"]["login"].stringValue + " · " + Helper.timeAgoSinceNow(topic["created_at"].stringValue) + " · " + (topic["hits"].int != nil ? topic["hits"].stringValue + " 次阅读" : "")

        rightButtons = Array(((topic["abilities"]["update"].boolValue ? [editButton] : [MGSwipeButton]()) + (topic["abilities"]["destroy"].boolValue ? [deleteButton] : [MGSwipeButton]())).reverse())

        frame.size.height = 10 + max(44, textLabel!.frame.height + 6 + detailTextLabel!.frame.height) + 10
        
        topicController?.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .None)
    }

    func user() {
        let webViewController = WebViewController()
        webViewController.path = Helper.baseURL.absoluteString! + "/" + topic["user"]["login"].stringValue
        webViewController.title = topic["user"]["login"].string
        topicController?.navigationController?.pushViewController(webViewController, animated: true)
    }
}
