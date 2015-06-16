//
//  TopicController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/22/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import AFNetworking
import CCBottomRefreshControl
import JTSImageViewController
import RegExCategories
import SDWebImage
import SwiftyJSON
import UIKit

class TopicController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate {

    var failureView = FailureView()
    var loadingView = LoadingView()
    var refreshing = false
    var replies: JSON = []
    var replyCells = [ReplyCell]()
    var tableView = UITableView()
    var topRefreshControl = UIRefreshControl()
    var topic: JSON = []
    var topicBodyCell = TopicBodyCell()
    var topicTitleCell = TopicTitleCell()


    override func viewDidLoad() {
        navigationItem.leftBarButtonItem = navigationController?.viewControllers.count == 1 ? splitViewController?.displayModeButtonItem() : nil
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.rightBarButtonItems = Array([
            UIBarButtonItem(barButtonSystemItem: .Reply, target: self, action: Selector("reply")),
            UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: Selector("action")),
        ].reverse())
        title = topic["title"].string
        view.backgroundColor = Helper.backgroundColor

        tableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        tableView.backgroundColor = .clearColor()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        topRefreshControl.addTarget(self, action: Selector("topRefresh"), forControlEvents: .ValueChanged)
        tableView.addSubview(topRefreshControl)

        let bottomRefreshControl = UIRefreshControl()
        bottomRefreshControl.addTarget(self, action: Selector("bottomRefresh"), forControlEvents: .ValueChanged)
        tableView.bottomRefreshControl = bottomRefreshControl

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("loadData")))
        view.addSubview(failureView)

        view.addSubview(loadingView)
    }

    override func viewWillAppear(animated: Bool) {
        if topic["body_html"].string == nil { autoRefresh() }
        Helper.trackView(self)
    }

    func autoRefresh() {
        if refreshing { return }
        loadingView.show()
        loadData()
    }

    func topRefresh() {
        if refreshing { topRefreshControl.endRefreshing(); return }
        topic["body_html"].string = nil
        topicBodyCell = TopicBodyCell()
        replies = []
        replyCells = []
        loadData()
    }

    func bottomRefresh() {
        if refreshing { tableView.bottomRefreshControl.endRefreshing(); tableView.bottomRefreshControl.hidden = true; return }
        loadData()
    }

    func stopRefresh() {
        refreshing = false
        loadingView.hide()
        topRefreshControl.endRefreshing()
        tableView.bottomRefreshControl.endRefreshing()
        tableView.bottomRefreshControl.hidden = true
    }

    func loadData() {
        if topic["body_html"].string != nil { loadReplies(); return }
        if refreshing { return }
        refreshing = true
        failureView.hide()
        let path = "/topics/" + topic["id"].stringValue + ".json"
        AFHTTPRequestOperationManager(baseURL: Helper.baseURL).GET(path, parameters: nil, success: { (operation, responseObject) in
            self.stopRefresh()
            self.topic = JSON(responseObject)["topic"]
            self.title = self.topic["title"].string
            self.tableView.reloadData()
            self.autoRefresh()
        }) { (operation, error) in
            self.stopRefresh()
            self.failureView.show()
        }
    }

    func loadReplies() {
        if refreshing { return }
        refreshing = true
        failureView.hide()
        let path = "/topics/" + topic["id"].stringValue + "/replies.json"
        let parameters = ["offset": replies.count, "limit": 30]
        AFHTTPRequestOperationManager(baseURL: Helper.baseURL).GET(path, parameters: parameters, success: { (operation, responseObject) in
            self.stopRefresh()
            let replies = JSON(responseObject)["replies"]
            if replies.count == 0 { return }
            self.replies = JSON(self.replies.arrayValue + replies.arrayValue)
            self.replyCells.extend((0...replies.count - 1).map({ (_) in ReplyCell() }))
            self.tableView.insertRowsAtIndexPaths((self.replies.count - replies.count...self.replies.count - 1).map({ NSIndexPath(forRow: $0, inSection: 2) }), withRowAnimation: .None)
        }) { (operation, error) in
            self.stopRefresh()
            self.failureView.show()
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2 { return String(max(replies.arrayValue.filter({ !$0["deleted"].boolValue }).count, topic["replies_count"].intValue)) + " 个回复" }
        return nil
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return replies.count
        default: return 0
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 10 + max(44, topicTitleCell.textLabel!.frame.height + 6 + topicTitleCell.detailTextLabel!.frame.height) + 10
        case 1: return 10 + max(44, topicBodyCell.webViewHeight) + 10
        case 2: return replies[indexPath.row]["deleted"].boolValue ? 44 : 10 + max(44, replyCells[indexPath.row].textLabel!.frame.height + 6 + replyCells[indexPath.row].webViewHeight) + 10
        default: 0
        }
        return tableView.rowHeight
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            topicTitleCell.topic = topic
            topicTitleCell.topicController = self
            return topicTitleCell
        case 1:
            if topic["body_html"].string == nil { break }
            topicBodyCell.topicController = self
            return topicBodyCell
        case 2:
            if replies[indexPath.row]["deleted"].boolValue {
                let cell = UITableViewCell()
                cell.selectionStyle = .None
                cell.textLabel?.attributedText = NSAttributedString(string: "已删除", attributes: [NSStrikethroughStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue])
                cell.textLabel?.font = .systemFontOfSize(14)
                cell.textLabel?.textAlignment = .Center
                cell.textLabel?.textColor = .lightGrayColor()
                return cell
            }
            if indexPath.row >= replyCells.count { break }
            let cell = replyCells[indexPath.row]
            cell.indexPath = indexPath
            cell.reply = replies[indexPath.row]
            cell.reply["topic_id"].object = topic["id"].object
            cell.topicController = self
            return cell
        default: 0
        }
        let cell = UITableViewCell()
        cell.selectionStyle = .None
        return cell
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 2 && indexPath.row + 1 == replies.count && indexPath.row + 1 < topic["replies_count"].intValue { autoRefresh() }
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        topicBodyCell = TopicBodyCell()
        replyCells = replyCells.map({ (_) in ReplyCell() })
        tableView.reloadData()
    }

    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .LinkClicked && contains(["http", "https"], request.URL!.scheme!) {
            let path = request.URL!.absoluteString!
            if path.isMatch("#reply\\d+$".toRx()) {
                let row = path.firstMatch("\\d+$".toRx()).toInt()! - 1
                if row >= replies.count { return false }
                tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: row, inSection: 2), atScrollPosition: .Top, animated: true)
                return false
            }
            if path.isMatch("#imageview$".toRx()) {
                let imageInfo = JTSImageInfo()
                imageInfo.imageURL = request.URL
                let imageViewController = JTSImageViewController(imageInfo: imageInfo, mode: .Image, backgroundStyle: .None)
                imageViewController.showFromViewController(self, transition: ._FromOffscreen)
                return false
            }
            if path.isMatch("^https?://ruby-china.org/topics/\\d+$".toRx()) {
                let topicController = TopicController()
                topicController.topic = ["id": path.firstMatch("\\d+$".toRx())]
                navigationController?.pushViewController(topicController, animated: true)
                return false
            }
            let webViewController = WebViewController()
            webViewController.path = path
            navigationController?.pushViewController(webViewController, animated: true)
            return false
        }
        return true
    }

    func action() {
        let activityViewController = UIActivityViewController(activityItems: [NSURL(string: Helper.baseURL.absoluteString! + "/topics/" + topic["id"].stringValue)!], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        presentViewController(activityViewController, animated: true, completion: nil)
    }

    func reply() {
        let composeController = ComposeController()
        composeController.reply["topic_id"].object = topic["id"].object
        navigationController?.pushViewController(composeController, animated: true)
    }

    func addReply(reply: JSON) {
        replies = JSON(replies.arrayValue + [reply])
        replyCells.append(ReplyCell())
        let indexPath = NSIndexPath(forRow: replies.count - 1, inSection: 2)
        tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        tableView.bottomRefreshControl.hidden = true
    }

    func updateReply(reply: JSON) {
        let row = filter(0...replies.count - 1) { self.replies[$0]["id"].intValue == reply["id"].intValue }.first ?? 0
        replies[row] = reply
        replyCells[row] = ReplyCell()
        let indexPath = NSIndexPath(forRow: row, inSection: 2)
        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .None)
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
        tableView.bottomRefreshControl.hidden = true
    }
}
