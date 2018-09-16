//
//  WebViewController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/28/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import UIKit

class WebViewController: UIViewController, UIWebViewDelegate {

    var failureView = FailureView()
    var loadingView = LoadingView()
    var path = ""
    var refreshControl = UIRefreshControl()
    var webView = UIWebView()


    override func viewDidLoad() {
        navigationItem.leftBarButtonItem = navigationController?.viewControllers.count == 1 ? splitViewController?.displayModeButtonItem : nil
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action))
        view.backgroundColor = Helper.backgroundColor

        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.backgroundColor = .clear
        webView.delegate = self
        webView.frame = view.bounds
        webView.isOpaque = false
        view.addSubview(webView)

        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loadData)))
        view.addSubview(failureView)

        view.addSubview(loadingView)
    }

    override func viewWillAppear(_ animated: Bool) {
        if webView.request == nil { loadData() }
        Helper.trackView(self)
    }

    func loadData() {
        guard let url = URL(string: path) else { return }
        webView.loadRequest(URLRequest(url: url))
    }

    func webViewDidStartLoad(_ webView: UIWebView) {
        failureView.hide()
        if !refreshControl.isRefreshing { loadingView.show() }
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        refreshControl.endRefreshing()
        loadingView.hide()
        title = title ?? webView.stringByEvaluatingJavaScript(from: "document.title")
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        refreshControl.endRefreshing()
        loadingView.hide()
        failureView.show()
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .linkClicked && ["http", "https"].contains(request.url?.scheme ?? "") {
            let webViewController = WebViewController()
            webViewController.path = request.url?.absoluteString ?? ""
            navigationController?.pushViewController(webViewController, animated: true)
            return false
        }
        return true
    }

    func refresh() {
        if loadingView.refreshing { refreshControl.endRefreshing(); return }
        webView.reload()
    }

    func action() {
        let activityViewController = UIActivityViewController(activityItems: [URL(string: path)!], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityViewController, animated: true, completion: nil)
    }
}
