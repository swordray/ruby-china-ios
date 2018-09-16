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
        navigationItem.leftBarButtonItem = navigationController?.viewControllers.count == 1 ? splitViewController?.displayModeButtonItem : nil
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(reply)),
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action)),
        ].reversed()
        title = topic["title"].string
        view.backgroundColor = Helper.backgroundColor

        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        topRefreshControl.addTarget(self, action: #selector(topRefresh), for: .valueChanged)
        tableView.addSubview(topRefreshControl)

        let bottomRefreshControl = UIRefreshControl()
        bottomRefreshControl.addTarget(self, action: #selector(bottomRefresh), for: .valueChanged)
        tableView.bottomRefreshControl = bottomRefreshControl

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loadData)))
        view.addSubview(failureView)

        view.addSubview(loadingView)
    }

    override func viewWillAppear(_ animated: Bool) {
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
        tableView.reloadData()
        loadData()
    }

    func bottomRefresh() {
        if refreshing { tableView.bottomRefreshControl.endRefreshing(); tableView.bottomRefreshControl.isHidden = true; return }
        loadData()
    }

    func stopRefresh() {
        refreshing = false
        loadingView.hide()
        topRefreshControl.endRefreshing()
        tableView.bottomRefreshControl.endRefreshing()
        tableView.bottomRefreshControl.isHidden = true
    }

    func loadData() {
        if topic["body_html"].string != nil { loadReplies(); return }
        if refreshing { return }
        refreshing = true
        failureView.hide()
        let path = "/topics/\(topic["id"]).json"
        AFHTTPSessionManager(baseURL: Helper.baseURL).get(path, parameters: nil, progress: nil, success: { task, responseObject in
            self.stopRefresh()
            self.topic = JSON(responseObject)["topic"]
            self.title = self.topic["title"].string
            self.tableView.reloadData()
            self.autoRefresh()
        }) { task, error in
            self.stopRefresh()
            self.failureView.show()
        }
    }

    func loadReplies() {
        if refreshing { return }
        refreshing = true
        failureView.hide()
        let path = "/topics/\(topic["id"])/replies.json"
        let parameters = ["offset": replies.count, "limit": 30]
        AFHTTPSessionManager(baseURL: Helper.baseURL).get(path, parameters: parameters, progress: nil, success: { task, responseObject in
            self.stopRefresh()
            let replies = JSON(responseObject)["replies"]
            if replies.count == 0 { return }
            self.replies = JSON(self.replies.arrayValue + replies.arrayValue)
            self.replyCells.append(contentsOf: (0...replies.count - 1).map { _ in ReplyCell() })
            self.tableView.insertRows(at: (self.replies.count - replies.count...self.replies.count - 1).map { IndexPath(row: $0, section: 2) }, with: .none)
        }) { task, error in
            self.stopRefresh()
            self.failureView.show()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2 { return "回复（\(max(replies.arrayValue.filter { !$0["deleted"].boolValue }.count, topic["replies_count"].intValue))）" }
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return replies.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 11.5 + max(44, topicTitleCell.textLabel!.frame.height + 5 + topicTitleCell.detailTextLabel!.frame.height) + 11.5
        case 1: return 11.5 + max(44, topicBodyCell.webViewHeight) + 11.5
        case 2: return indexPath.row > replies.count - 1 ? 11.5 + 44 + 11.5 : replies[indexPath.row]["body_html"].string == nil ? 0 : replies[indexPath.row]["deleted"].boolValue ? 44 : 11.5 + max(44, replyCells[indexPath.row].textLabel!.frame.height + 5 + replyCells[indexPath.row].webViewHeight) + 11.5
        default: Void()
        }
        return tableView.rowHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            topicTitleCell.separatorInset.left = tableView.separatorInset.left
            topicTitleCell.topic = topic
            topicTitleCell.topicController = self
            return topicTitleCell
        case 1:
            if topic["body_html"].string == nil { break }
            topicBodyCell.separatorInset.left = tableView.separatorInset.left
            topicBodyCell.topicController = self
            return topicBodyCell
        case 2:
            if replies[indexPath.row]["body_html"].string == nil {
                return UITableViewCell()
            }
            if replies[indexPath.row]["deleted"].boolValue {
                let cell = UITableViewCell()
                cell.selectionStyle = .none
                cell.separatorInset.left = tableView.separatorInset.left
                cell.textLabel?.attributedText = NSAttributedString(string: "已删除", attributes: [NSStrikethroughStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue])
                cell.textLabel?.font = .preferredFont(forTextStyle: .subheadline)
                cell.textLabel?.textAlignment = .center
                cell.textLabel?.textColor = .lightGray
                return cell
            }
            if indexPath.row >= replyCells.count { break }
            let cell = replyCells[indexPath.row]
            cell.indexPath = indexPath
            cell.reply = replies[indexPath.row]
            cell.reply["topic_id"] = topic["id"]
            cell.separatorInset.left = tableView.separatorInset.left
            cell.topicController = self
            return cell
        default: Void()
        }
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 2 && indexPath.row + 1 == replies.count && indexPath.row + 1 < topic["replies_count"].intValue { autoRefresh() }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        topicTitleCell = TopicTitleCell()
        topicBodyCell = TopicBodyCell()
        replyCells = replyCells.map { _ in ReplyCell() }
        tableView.reloadData()
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType == .linkClicked && ["http", "https"].contains(request.url?.scheme ?? "") {
            let path = request.url?.absoluteString ?? ""
            if path.isMatch("#reply\\d+$".toRx()) {
                let row = Int(path.firstMatch("\\d+$".toRx()))! - 1
                if row >= replies.count { return false }
                tableView.scrollToRow(at: IndexPath(row: row, section: 2), at: .top, animated: true)
                return false
            }
            if path.isMatch("#imageview$".toRx()) {
                let imageInfo = JTSImageInfo()
                imageInfo.imageURL = request.url
                let imageViewController = JTSImageViewController(imageInfo: imageInfo, mode: .image, backgroundStyle: JTSImageViewControllerBackgroundOptions())
                imageViewController?.show(from: self, transition: .fromOffscreen)
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
        guard let url = URL(string: "\(Helper.baseURL.absoluteString)/topics/\(topic["id"])") else { return }
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityViewController, animated: true, completion: nil)
    }

    func reply() {
        let composeController = ComposeController()
        composeController.reply["topic_id"] = topic["id"]
        navigationController?.pushViewController(composeController, animated: true)
    }

    func addReply(_ reply: JSON) {
        replies = JSON(replies.arrayValue + [reply])
        replyCells.append(ReplyCell())
        let indexPath = IndexPath(row: replies.count - 1, section: 2)
        tableView.insertRows(at: [indexPath], with: .none)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        tableView.bottomRefreshControl.isHidden = true
    }

    func updateReply(_ reply: JSON) {
        let row = (0...replies.count - 1).filter { self.replies.arrayValue[$0]["id"].intValue == reply["id"].intValue }.first ?? 0
        replies[row] = reply
        replyCells[row] = ReplyCell()
        let indexPath = IndexPath(row: row, section: 2)
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        tableView.bottomRefreshControl.isHidden = true
    }
}
