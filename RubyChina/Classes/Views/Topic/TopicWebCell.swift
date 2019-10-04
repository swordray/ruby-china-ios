//
//  TopicCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit
import WebKit

class TopicWebCell: UITableViewCell {

    public  var bodyHTML: String? { didSet { didSetBodyHTML() } }
    public  var webView: UIWebView!
    private var webViewObservation: NSKeyValueObservation?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        webView = UIWebView()
        webView.backgroundColor = .clear
        webView.dataDetectorTypes = []
        webView.delegate = self
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false
        webView.snp.makeConstraints { $0.height.equalTo(Int(UIFont.preferredFont(forTextStyle: .body).pointSize)).priority(999) }

        webViewObservation = webView.observe(\.scrollView.contentSize) { webView, _ in
            webView.snp.updateConstraints { $0.height.equalTo(webView.scrollView.contentSize.height).priority(999) }
            let tableView = self.next(of: UITableView.self)
            guard let indexPath = tableView?.indexPath(for: self) else { return }
            tableView?.reloadRows(at: [indexPath], with: .none)
        }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func didSetBodyHTML() {
        guard let htmlString = htmlString, webView.request == nil else { return }
        webView.loadHTMLString(htmlString, baseURL: viewController?.baseURL)
    }

    private var htmlString: String? {
        guard let bodyHTML = bodyHTML else { return nil }
        let style = """
            *, *::before, *::after { box-sizing: border-box; padding: 0; margin: 0; }
            :root { color-scheme: light dark; }
            html, body { width: 100%; height: 100%; font-family: -apple-system; font: -apple-system-body; word-wrap: break-word; -webkit-tap-highlight-color: transparent; }
            h1, h2, h3, h4, h5, h6 { margin: 1.5em 0 1em; font: -apple-system-title3; }
            ol, ul { padding-left: 1.5em; margin: 1em 0; }
            ol { list-style-type: decimal; }
            ul { list-style-type: disc; }
            li { margin: 0.5em 0; }
            table { max-width: 100%; margin: 1em 0; border-collapse: collapse; }
            table tr th { font-weight: normal; background-color: #f2f2f7; }
            @media (prefers-color-scheme: dark) { table tr th { background-color: #1c1c1e; } }
            table tr th, table tr td { padding: 0.25em 0.5em; border-bottom: 0.5px solid rgba(60, 60, 67, 0.29); }
            @media (prefers-color-scheme: dark) { table tr th, table tr td { background-color: rgba(84, 84, 88, 0.65); } }
            hr { margin: 1em 0; border: none; border-bottom: 0.5px solid #c6c6c8; }
            @media (prefers-color-scheme: dark) { hr { border-bottom-color: #38383a; } }
            pre { padding: 0.5em; margin: 1em 0; font: -apple-system-footnote; white-space: pre-wrap; background-color: #f2f2f7; }
            @media (prefers-color-scheme: dark) { pre { background-color: #1c1c1e; } }
            code { display: inline-block; max-width: 100%; padding: 0 0.2em; margin: 0 0.2em; background-color: #f2f2f7; }
            @media (prefers-color-scheme: dark) { code { background-color: #1c1c1e; } }
            blockquote { padding-left: 1em; margin: 1em 0; color: rgba(60, 60, 67, 0.6); border-left: 2px solid #c6c6c8; }
            @media (prefers-color-scheme: dark) { blockquote { color: rgba(235, 235, 245, 0.6); border-left-color: #38383a; } }
            p { margin: 0.5em 0; }
            a { color: #9b111e; text-decoration: none; }
            @media (prefers-color-scheme: dark) { a { color: #e0115f; } }
            a.at_floor { color: #34c759; }
            @media (prefers-color-scheme: dark) { a.at_floor { color: #32d74b; } }
            img { max-width: 100%; }
            img.emoji, img.twemoji { width: 1em; height: 1em; vertical-align: sub; }
            .embed-responsive { position: relative; display: block; overflow: hidden; }
            .embed-responsive::before { display: block; padding-top: 56.25%; content: ''; }
            .embed-responsive .embed-responsive-item {  position: absolute; top: 0; bottom: 0; left: 0; width: 100%; height: 100%; border: 0; }
            body :first-child { margin-top: 0; }
            body :last-child { margin-bottom: 0; }
        """
        let script = """
            document.addEventListener('DOMContentLoaded', function(event) {
                var images = document.querySelectorAll('img:not(.emoji):not(.twemoji)')
                for (var i = 0; i < images.length; i++) {
                    var image = images[i]
                    var a = document.createElement('a')
                    a.href = image.src + '#imageview'
                    image.parentElement.insertBefore(a, image)
                    a.appendChild(image)
                }
            })
        """
        return """
            <!DOCTYPE html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <style>\(style)</style>
                    <script>\(script)</script>
                </head>
                <body>\(bodyHTML)</body>
            </html>
        """
    }
}

extension TopicWebCell: UIWebViewDelegate {

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        guard navigationType == .linkClicked, let url = request.url else { return true }
        if url.scheme == "applewebdata" {
            if let fragment = url.fragment, let index = Int("^reply(\\d+)$".r?.findFirst(in: fragment)?.group(at: 1) ?? "") {
                let indexPath = IndexPath(row: index - 1, section: 2)
                (viewController as? TopicController)?.scrollToReply(indexPath)
            } else if let internalURL = viewController?.baseURL.appendingPathComponent(url.path) {
                let webViewController = WebViewController()
                webViewController.url = internalURL
                viewController?.navigationController?.pushViewController(webViewController, animated: true)
            }
        } else if url.host == "ruby-china.org", let id = "^/topics/(\\d+)$".r?.findFirst(in: url.path)?.group(at: 1) {
            let topicController = TopicController()
            topicController.topic = try? Topic(json: ["id": Int(id)])
            viewController?.navigationController?.pushViewController(topicController, animated: true)
        } else if WKWebView.handlesURLScheme(url.scheme ?? "") {
            let webViewController = WebViewController()
            webViewController.title = url.fragment == "imageview" ? "图片" : nil
            webViewController.url = url
            viewController?.navigationController?.pushViewController(webViewController, animated: true)
        } else if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        return false
    }
}
