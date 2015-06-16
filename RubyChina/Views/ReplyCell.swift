//
//  ReplyCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/28/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import AFNetworking
import MBProgressHUD
import MGSwipeTableCell
import SwiftyJSON
import UIKit

class ReplyCell: MGSwipeTableCell, UIWebViewDelegate {

    var deleteButton = MGSwipeButton()
    var editButton = MGSwipeButton()
    var indexPath = NSIndexPath()
    var reply: JSON = [:]
    var replyButton = MGSwipeButton()
    var topicController: TopicController?
    var webView = UIWebView()
    var webViewHeight = CGFloat.min


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .None

        imageView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("user")))
        imageView?.layer.cornerRadius = 3
        imageView?.layer.masksToBounds = true
        imageView?.userInteractionEnabled = true

        textLabel?.font = .systemFontOfSize(14)
        textLabel?.textColor = .lightGrayColor()

        webView.backgroundColor = .clearColor()
        webView.delegate = self
        webView.opaque = false
        webView.scrollView.scrollEnabled = false
        contentView.addSubview(webView)

        replyButton.backgroundColor = Helper.tintColor
        replyButton.buttonWidth = 72
        replyButton.callback = { (_) in
            let composeController = ComposeController()
            composeController.reply["body"].object = "#\(self.indexPath.row + 1)楼 @" + self.reply["user"]["login"].stringValue + " "
            composeController.reply["topic_id"].object = self.reply["topic_id"].object
            self.topicController?.navigationController?.pushViewController(composeController, animated: true)
            return true
        }
        replyButton.setTitle("回复", forState: .Normal)

        editButton.backgroundColor = UIColor(red: 199/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1)
        editButton.buttonWidth = 72
        editButton.callback = { (_) in
            let composeController = ComposeController()
            composeController.reply = self.reply
            self.topicController?.navigationController?.pushViewController(composeController, animated: true)
            return true
        }
        editButton.setTitle("编辑", forState: .Normal)

        deleteButton.backgroundColor = UIColor(red: 255/255.0, green: 59/255.0, blue: 48/255.0, alpha: 1)
        deleteButton.buttonWidth = 72
        deleteButton.callback = { (_) in
            let alertController = UIAlertController(title: "确定删除吗？", message: nil, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "删除", style: .Default, handler: { (_) in
                let progressHUD = MBProgressHUD.showHUDAddedTo(self.topicController!.view, animated: false)
                AFHTTPRequestOperationManager(baseURL: Helper.baseURL).DELETE("/replies/" + self.reply["id"].stringValue + ".json", parameters: nil, success: { (operation, responseObject) in
                    progressHUD.hide(false)
                    self.topicController?.replies[self.indexPath.row]["deleted"].bool = true
                    self.topicController?.tableView.reloadRowsAtIndexPaths([self.indexPath], withRowAnimation: .None)
                }) { (operation, error) in
                    if operation.response != nil && operation.response.statusCode == 401 { progressHUD.hide(false); Helper.signIn(self.topicController); return }
                    progressHUD.labelText = "网络错误"
                    progressHUD.mode = .Text
                    progressHUD.hide(true, afterDelay: 2)
                }
            }))
            self.topicController?.presentViewController(alertController, animated: true, completion: nil)
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
        imageView?.sd_setImageWithURL(NSURL(string: reply["user"]["avatar_url"].stringValue)!, placeholderImage: Helper.blankImage(imageView!.frame.size))

        textLabel?.frame = CGRect(x: separatorInset.left * 2 + 44, y: 10, width: frame.width - separatorInset.left * 3 - 44, height: 17)
        textLabel?.text = reply["user"]["login"].stringValue + " · #\(indexPath.row + 1) · " + Helper.timeAgoSinceNow(reply["created_at"].string)

        webView.frame = CGRect(x: separatorInset.left * 2 + 44, y: 10 + textLabel!.frame.height + 6, width: frame.width - separatorInset.left * 3 - 44, height: webViewHeight)
        webView.request == nil ? webView.loadHTMLString(html(reply["body_html"].stringValue), baseURL: Helper.baseURL) : webViewDidFinishLoad(webView)

        rightButtons = Array(([replyButton] + (reply["abilities"]["update"].boolValue ? [editButton] : [MGSwipeButton]()) + (reply["abilities"]["destroy"].boolValue ? [deleteButton] : [MGSwipeButton]())).reverse())
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        let height = webView.scrollView.contentSize.height
        if height == webViewHeight { return }
        webViewHeight = height
        topicController?.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        frame.size.height = 10 + max(44, textLabel!.frame.height + 6 + height) + 10
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return topicController!.webView(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
    }

    func html(body: String) -> String {
        let version = JSON(NSBundle.mainBundle().infoDictionary!)["CFBundleShortVersionString"].stringValue
        return "<!DOCTYPE html><html><head><link rel='stylesheet' media='screen' href='\(Helper.baseURL.absoluteString!)/application.css?version=\(version)' /><script src='\(Helper.baseURL.absoluteString!)/application.js?version=\(version)'></script></head><body><div id='page'>\(body)</div></body></html>";
    }

    func user() {
        let webViewController = WebViewController()
        webViewController.path = Helper.baseURL.absoluteString! + "/" + reply["user"]["login"].stringValue
        webViewController.title = reply["user"]["login"].string
        topicController?.navigationController?.pushViewController(webViewController, animated: true)
    }
}
