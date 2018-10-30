//
//  WebViewController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import JXWebViewController
import WebKit

class WebViewController: JXWebViewController {

    private var activityIndicatorView: ActivityIndicatorView!
    private var isRefreshing = false { didSet { didSetRefreshing() } }
    private var networkErrorView: NetworkErrorView!
    public  var url: URL!

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action))

        let userScript = WKUserScript(source: "if (typeof(Turbolinks) !== 'undefined') { Turbolinks.supported = false }", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webViewConfiguration.userContentController.addUserScript(userScript)
    }

    override func loadView() {
        super.loadView()

        view.backgroundColor = .white

        if title != nil {
            webViewKeyValueObservations[\WKWebView.title] = nil
        }

        activityIndicatorView = ActivityIndicatorView()
        view.addSubview(activityIndicatorView)

        networkErrorView = NetworkErrorView()
        networkErrorView.addGestureRecognizer(UITapGestureRecognizer(target: webView, action: #selector(webView.reload)))
        view.addSubview(networkErrorView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.leftBarButtonItem = self == navigationController?.viewControllers.first ? splitViewController?.displayModeButtonItem : nil

        if webView.url == nil {
            webView.load(URLRequest(url: url))
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.preferredContentSize.height = UIScreen.main.bounds.height

        GAI.sharedInstance().defaultTracker.send([kGAIHitType: "appview", kGAIScreenName: String(describing: type(of: self))])
    }

    private func didSetRefreshing() {
        if isRefreshing {
            networkErrorView.isHidden = true
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }

    @objc
    private func action(_ barButtonItem: UIBarButtonItem) {
        guard let url = webView.url else { return }
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
        present(activityViewController, animated: true)
    }
}

extension WebViewController {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        isRefreshing = true
    }

    override func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        super.webView(webView, didFailProvisionalNavigation: navigation, withError: error)

        isRefreshing = false
        networkErrorView.isHidden = false
    }

    override func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        super.webView(webView, didFail: navigation, withError: error)

        isRefreshing = false
        networkErrorView.isHidden = false
    }

    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        super.webView(webView, didFinish: navigation)

        isRefreshing = false
    }

    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, url.host == "ruby-china.org", let id = "^/topics/(\\d+)$".r?.findFirst(in: url.path)?.group(at: 1) {
            let topicController = TopicController()
            topicController.topic = try? Topic(json: ["id": Int(id)])
            show(topicController, sender: nil)
            decisionHandler(.cancel)
            return
        }

        super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }
}
