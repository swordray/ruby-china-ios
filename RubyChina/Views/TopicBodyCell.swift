//
//  TopicBodyCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 6/3/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import UIKit

class TopicBodyCell: UITableViewCell, UIWebViewDelegate {

    weak var topicController: TopicController?
    var webView = UIWebView()
    var webViewHeight = CGFloat.leastNormalMagnitude


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        webView.backgroundColor = .clear
        webView.delegate = self
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        contentView.addSubview(webView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        webView.frame = CGRect(x: separatorInset.left, y: 11.5, width: frame.width - separatorInset.left * 2, height: webViewHeight)
        webView.request == nil ? webView.loadHTMLString(html(topicController!.topic["body_html"].stringValue), baseURL: Helper.baseURL) : webViewDidFinishLoad(webView)
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        let height = webView.scrollView.contentSize.height
        if height == webViewHeight { return }
        webViewHeight = height
        topicController?.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
        frame.size.height = 11.5 + max(44, height) + 11.5
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return topicController!.webView(webView, shouldStartLoadWith: request, navigationType: navigationType)
    }

    func html(_ body: String) -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? ""
        return "<!DOCTYPE html><html><head><link rel='stylesheet' media='screen' href='\(Helper.baseURL.absoluteString)/application.css?version=\(version)' /><script src='\(Helper.baseURL.absoluteString)/application.js?version=\(version)'></script></head><body><div id='page'>\(body)</div></body></html>";
    }
}
