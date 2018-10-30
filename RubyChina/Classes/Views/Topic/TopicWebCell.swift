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
            html, body { width: 100%; height: 100%; font-family: -apple-system; font: -apple-system-body; background-color: white; word-wrap: break-word; -webkit-tap-highlight-color: transparent; }
            h1, h2, h3, h4, h5, h6 { margin: 2em 0 1em; font: -apple-system-title3; }
            ol, ul { padding-left: 1.5em; margin: 1em 0; }
            ol { list-style-type: decimal; }
            ul { list-style-type: disc; }
            li { margin: 0.5em 0; }
            table { max-width: 100%; margin: 1em 0; border-collapse: collapse; }
            table tr th { font-weight: normal; background-color: #f8f8f8; }
            table tr th, table tr td { padding: 0.25em 0.5em; border-bottom: 0.5px solid #c7c7cc; }
            hr { margin: 1em 0; border: none; border-bottom: 0.5px solid #c7c7cc; }
            @media (-webkit-min-device-pixel-ratio: 3), (min-resolution: 3dppx) { table tr th, table tr td, hr { border-bottom-width: 0.3333px; } }
            pre { padding: 0.5em; margin: 1em 0; font: -apple-system-footnote; white-space: pre-wrap; }
            pre, pre code { background-color: #f8f8f8; }
            code { display: inline-block; max-width: 100%; padding: 0 0.2em; margin: 0 0.2em; background-color: #f0f0f0; }
            blockquote { padding-left: 1em; margin: 1em 0; color: #8e8e93; border-left: 2px solid #e5e5ea; }
            p { margin: 0.5em 0; }
            a { color: #9b111e; text-decoration: none; }
            a:active { opacity: 0.2; }
            a.at_floor { color: #60b566; }
            img { max-width: 100%; }
            img.emoji, img.twemoji { width: 1em; height: 1em; vertical-align: sub; }
            .embed-responsive { position: relative; display: block; overflow: hidden; }
            .embed-responsive::before { display: block; padding-top: 56.25%; content: ''; }
            .embed-responsive .embed-responsive-item {  position: absolute; top: 0; bottom: 0; left: 0; width: 100%; height: 100%; border: 0; }
            body :first-child { margin-top: 0; }
            body :last-child { margin-bottom: 0; }
            .highlight .hll { background-color: #ffffcc }
            .highlight  { background: #f8f8f8; }
            .highlight .c { color: #008800; font-style: italic } /* Comment */
            .highlight .err { border: 1px solid #FF0000 } /* Error */
            .highlight .k { color: #AA22FF; font-weight: bold } /* Keyword */
            .highlight .o { color: #666666 } /* Operator */
            .highlight .ch { color: #008800; font-style: italic } /* Comment.Hashbang */
            .highlight .cm { color: #008800; font-style: italic } /* Comment.Multiline */
            .highlight .cp { color: #008800 } /* Comment.Preproc */
            .highlight .cpf { color: #008800; font-style: italic } /* Comment.PreprocFile */
            .highlight .c1 { color: #008800; font-style: italic } /* Comment.Single */
            .highlight .cs { color: #008800; font-weight: bold } /* Comment.Special */
            .highlight .gd { color: #A00000 } /* Generic.Deleted */
            .highlight .ge { font-style: italic } /* Generic.Emph */
            .highlight .gr { color: #FF0000 } /* Generic.Error */
            .highlight .gh { color: #000080; font-weight: bold } /* Generic.Heading */
            .highlight .gi { color: #00A000 } /* Generic.Inserted */
            .highlight .go { color: #888888 } /* Generic.Output */
            .highlight .gp { color: #000080; font-weight: bold } /* Generic.Prompt */
            .highlight .gs { font-weight: bold } /* Generic.Strong */
            .highlight .gu { color: #800080; font-weight: bold } /* Generic.Subheading */
            .highlight .gt { color: #0044DD } /* Generic.Traceback */
            .highlight .kc { color: #AA22FF; font-weight: bold } /* Keyword.Constant */
            .highlight .kd { color: #AA22FF; font-weight: bold } /* Keyword.Declaration */
            .highlight .kn { color: #AA22FF; font-weight: bold } /* Keyword.Namespace */
            .highlight .kp { color: #AA22FF } /* Keyword.Pseudo */
            .highlight .kr { color: #AA22FF; font-weight: bold } /* Keyword.Reserved */
            .highlight .kt { color: #00BB00; font-weight: bold } /* Keyword.Type */
            .highlight .m { color: #666666 } /* Literal.Number */
            .highlight .s { color: #BB4444 } /* Literal.String */
            .highlight .na { color: #BB4444 } /* Name.Attribute */
            .highlight .nb { color: #AA22FF } /* Name.Builtin */
            .highlight .nc { color: #0000FF } /* Name.Class */
            .highlight .no { color: #880000 } /* Name.Constant */
            .highlight .nd { color: #AA22FF } /* Name.Decorator */
            .highlight .ni { color: #999999; font-weight: bold } /* Name.Entity */
            .highlight .ne { color: #D2413A; font-weight: bold } /* Name.Exception */
            .highlight .nf { color: #00A000 } /* Name.Function */
            .highlight .nl { color: #A0A000 } /* Name.Label */
            .highlight .nn { color: #0000FF; font-weight: bold } /* Name.Namespace */
            .highlight .nt { color: #008000; font-weight: bold } /* Name.Tag */
            .highlight .nv { color: #B8860B } /* Name.Variable */
            .highlight .ow { color: #AA22FF; font-weight: bold } /* Operator.Word */
            .highlight .w { color: #bbbbbb } /* Text.Whitespace */
            .highlight .mb { color: #666666 } /* Literal.Number.Bin */
            .highlight .mf { color: #666666 } /* Literal.Number.Float */
            .highlight .mh { color: #666666 } /* Literal.Number.Hex */
            .highlight .mi { color: #666666 } /* Literal.Number.Integer */
            .highlight .mo { color: #666666 } /* Literal.Number.Oct */
            .highlight .sa { color: #BB4444 } /* Literal.String.Affix */
            .highlight .sb { color: #BB4444 } /* Literal.String.Backtick */
            .highlight .sc { color: #BB4444 } /* Literal.String.Char */
            .highlight .dl { color: #BB4444 } /* Literal.String.Delimiter */
            .highlight .sd { color: #BB4444; font-style: italic } /* Literal.String.Doc */
            .highlight .s2 { color: #BB4444 } /* Literal.String.Double */
            .highlight .se { color: #BB6622; font-weight: bold } /* Literal.String.Escape */
            .highlight .sh { color: #BB4444 } /* Literal.String.Heredoc */
            .highlight .si { color: #BB6688; font-weight: bold } /* Literal.String.Interpol */
            .highlight .sx { color: #008000 } /* Literal.String.Other */
            .highlight .sr { color: #BB6688 } /* Literal.String.Regex */
            .highlight .s1 { color: #BB4444 } /* Literal.String.Single */
            .highlight .ss { color: #B8860B } /* Literal.String.Symbol */
            .highlight .bp { color: #AA22FF } /* Name.Builtin.Pseudo */
            .highlight .fm { color: #00A000 } /* Name.Function.Magic */
            .highlight .vc { color: #B8860B } /* Name.Variable.Class */
            .highlight .vg { color: #B8860B } /* Name.Variable.Global */
            .highlight .vi { color: #B8860B } /* Name.Variable.Instance */
            .highlight .vm { color: #B8860B } /* Name.Variable.Magic */
            .highlight .il { color: #666666 } /* Literal.Number.Integer.Long */
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
                viewController?.show(webViewController, sender: nil)
            }
        } else if url.host == "ruby-china.org", let id = "^/topics/(\\d+)$".r?.findFirst(in: url.path)?.group(at: 1) {
            let topicController = TopicController()
            topicController.topic = try? Topic(json: ["id": Int(id)])
            viewController?.show(topicController, sender: nil)
        } else if WKWebView.handlesURLScheme(url.scheme ?? "") {
            let webViewController = WebViewController()
            webViewController.title = url.fragment == "imageview" ? "图片" : nil
            webViewController.url = url
            viewController?.show(webViewController, sender: nil)
        } else if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        return false
    }
}
