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
    var indexPath = IndexPath()
    var reply: JSON = [:]
    var replyButton = MGSwipeButton()
    var topicController: TopicController?
    var webView = UIWebView()
    var webViewHeight = CGFloat.leastNormalMagnitude


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        imageView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(user)))
        imageView?.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        imageView?.layer.cornerRadius = 22
        imageView?.layer.masksToBounds = true
        imageView?.isUserInteractionEnabled = true

        textLabel?.font = .preferredFont(forTextStyle: .subheadline)
        textLabel?.textColor = .lightGray

        webView.backgroundColor = .clear
        webView.delegate = self
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        contentView.addSubview(webView)

        replyButton.backgroundColor = Helper.tintColor
        replyButton.buttonWidth = 66
        replyButton.callback = { _ in
            let composeController = ComposeController()
            composeController.reply["body"].object = "#\(self.indexPath.row + 1)楼 @ \(self.reply["user"]["login"]) "
            composeController.reply["topic_id"] = self.reply["topic_id"]
            self.topicController?.navigationController?.pushViewController(composeController, animated: true)
            return true
        }
        replyButton.setTitle("回复", for: .normal)

        editButton.backgroundColor = UIColor(red: 199/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1)
        editButton.buttonWidth = 66
        editButton.callback = { _ in
            let composeController = ComposeController()
            composeController.reply = self.reply
            self.topicController?.navigationController?.pushViewController(composeController, animated: true)
            return true
        }
        editButton.setTitle("编辑", for: .normal)

        deleteButton.backgroundColor = UIColor(red: 255/255.0, green: 59/255.0, blue: 48/255.0, alpha: 1)
        deleteButton.buttonWidth = 66
        deleteButton.callback = { _ in
            let alertController = UIAlertController(title: "确定删除吗？", message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "删除", style: .default) { _ in
                let progressHUD = MBProgressHUD.showAdded(to: self.topicController!.view, animated: false)
                let path = "/replies/\(self.reply["id"]).json"
                AFHTTPSessionManager(baseURL: Helper.baseURL).delete(path, parameters: nil, success: { task, responseObject in
                    progressHUD.hide(animated: false)
                    self.topicController?.replies[self.indexPath.row]["deleted"].bool = true
                    self.topicController?.tableView.reloadRows(at: [self.indexPath], with: .none)
                }) { task, error in
                    progressHUD.hide(animated: false)
                    if (task?.response as? HTTPURLResponse)?.statusCode == 401 { self.topicController?.signIn(); return }
                    self.topicController?.alert("网络错误")
                }
            })
            self.topicController?.present(alertController, animated: true, completion: nil)
            return false
        }
        deleteButton.setTitle("删除", for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView?.frame = CGRect(x: separatorInset.left, y: 11.5, width: 44, height: 44)
        if let url = URL(string: reply["user"]["avatar_url"].stringValue) { imageView?.setImageWith(url, placeholderImage: Helper.blankImage(imageView!.frame.size)) }

        textLabel?.frame = CGRect(x: separatorInset.left + 44 + 15, y: 11.5, width: frame.width - separatorInset.left * 2 - 44 - 15, height: 18)
        textLabel?.text = "\(reply["user"]["login"]) · #\(indexPath.row + 1) · \(Helper.timeAgoSinceNow(reply["created_at"].string))"

        webView.frame = CGRect(x: separatorInset.left + 44 + 15, y: 11.5 + textLabel!.frame.height + 5, width: frame.width - separatorInset.left * 2 - 44 - 15, height: webViewHeight)
        webView.request == nil ? webView.loadHTMLString(html(reply["body_html"].stringValue), baseURL: Helper.baseURL) : webViewDidFinishLoad(webView)

        rightButtons = [replyButton]
        if reply["abilities"]["update"].boolValue { rightButtons.append(editButton) }
        if reply["abilities"]["destroy"].boolValue { rightButtons.append(deleteButton) }
        rightButtons.reverse()
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        let height = webView.scrollView.contentSize.height
        if height == webViewHeight { return }
        webViewHeight = height
        if topicController?.tableView.cellForRow(at: indexPath) != nil { topicController?.tableView.reloadRows(at: [indexPath], with: .none) }
        frame.size.height = 11.5 + max(44, textLabel!.frame.height + 5 + height) + 11.5
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return topicController!.webView(webView, shouldStartLoadWith: request, navigationType: navigationType)
    }

    func html(_ body: String) -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? ""
        return "<!DOCTYPE html><html><head><link rel='stylesheet' media='screen' href='\(Helper.baseURL.absoluteString)/application.css?version=\(version)' /><script src='\(Helper.baseURL.absoluteString)/application.js?version=\(version)'></script></head><body><div id='page'>\(body)</div></body></html>";
    }

    func user() {
        let webViewController = WebViewController()
        webViewController.path = "\(Helper.baseURL.absoluteString)/\(reply["user"]["login"])"
        webViewController.title = reply["user"]["login"].string
        topicController?.navigationController?.pushViewController(webViewController, animated: true)
    }
}
