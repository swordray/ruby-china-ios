//
//  TopicBodyCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 6/3/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import SwiftyJSON
import UIKit

class TopicBodyCell: UITableViewCell, UIWebViewDelegate {

    var topicController: TopicController?
    var webView = UIWebView()
    var webViewHeight = CGFloat.min


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .None

        webView.backgroundColor = .clearColor()
        webView.delegate = self
        webView.opaque = false
        webView.scrollView.scrollEnabled = false
        contentView.addSubview(webView)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        webView.frame = CGRect(x: separatorInset.left, y: 10, width: frame.width - separatorInset.left * 2, height: webViewHeight)
        webView.request == nil ? webView.loadHTMLString(html(topicController!.topic["body_html"].stringValue), baseURL: Helper.baseURL) : webViewDidFinishLoad(webView)
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        let height = webView.scrollView.contentSize.height
        if height == webViewHeight { return }
        webViewHeight = height
        topicController?.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 1)], withRowAnimation: .None)
        frame.size.height = 10 + max(44, height) + 10
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return topicController!.webView(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
    }

    func html(body: String) -> String {
        let version = JSON(NSBundle.mainBundle().infoDictionary!)["CFBundleShortVersionString"].stringValue
        return "<!DOCTYPE html><html><head><link rel='stylesheet' media='screen' href='\(Helper.baseURL.absoluteString!)/application.css?version=\(version)' /><script src='\(Helper.baseURL.absoluteString!)/application.js?version=\(version)'></script></head><body><div id='page'>\(body)</div></body></html>";
    }
}
