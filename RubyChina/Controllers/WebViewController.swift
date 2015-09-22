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
        navigationItem.leftBarButtonItem = navigationController?.viewControllers.count == 1 ? splitViewController?.displayModeButtonItem() : nil
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: Selector("action"))
        view.backgroundColor = Helper.backgroundColor

        webView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        webView.backgroundColor = .clearColor()
        webView.delegate = self
        webView.frame = view.bounds
        webView.opaque = false
        view.addSubview(webView)

        refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: .ValueChanged)
        webView.scrollView.addSubview(refreshControl)

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("loadData")))
        view.addSubview(failureView)

        view.addSubview(loadingView)
    }

    override func viewWillAppear(animated: Bool) {
        if webView.request == nil { loadData() }
        Helper.trackView(self)
    }

    func loadData() {
        webView.loadRequest(NSURLRequest(URL: NSURL(string: path)!))
    }

    func webViewDidStartLoad(webView: UIWebView) {
        failureView.hide()
        if !refreshControl.refreshing { loadingView.show() }
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        refreshControl.endRefreshing()
        loadingView.hide()
        title = title ?? webView.stringByEvaluatingJavaScriptFromString("document.title")
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        refreshControl.endRefreshing()
        loadingView.hide()
        failureView.show()
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .LinkClicked && ["http", "https"].contains((request.URL!.scheme)) {
            let webViewController = WebViewController()
            webViewController.path = request.URL!.absoluteString
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
        let activityViewController = UIActivityViewController(activityItems: [NSURL(string: path)!], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        presentViewController(activityViewController, animated: true, completion: nil)
    }
}
