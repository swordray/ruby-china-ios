//
//  TopicController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import Alamofire
import TUSafariActivity

class TopicController: ViewController {

    private var activityIndicatorView: ActivityIndicatorView!
    private var bodyCell: TopicBodyCell?
    private var isRefreshing = false { didSet { didSetRefreshing() } }
    private var networkErrorView: NetworkErrorView!
    public  var replies: [Reply]? { didSet { didSetReplies() } }
    private var replyCells: [TopicReplyCell] = []
    private var tableView: UITableView!
    public  var topic: Topic? { didSet { didSetTopic() } }

    override init() {
        super.init()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .reply, target: self, action: #selector(newReply)),
            UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action)),
        ].reversed()

        userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    }

    override func loadView() {
        tableView = UITableView()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(fetchData), for: .valueChanged)
        tableView.register(TopicReplyDeletedCell.self, forCellReuseIdentifier: TopicReplyDeletedCell.description())
        tableView.register(TopicTitleCell.self, forCellReuseIdentifier: TopicTitleCell.description())
        tableView.tableFooterView = UIView()
        view = tableView

        activityIndicatorView = ActivityIndicatorView()
        view.addSubview(activityIndicatorView)

        networkErrorView = NetworkErrorView()
        networkErrorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(fetchData)))
        view.addSubview(networkErrorView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if topic?.bodyHTML == nil || !networkErrorView.isHidden { fetchData() }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { _ in
            self.didSetReplies()
            self.didSetTopic()
            self.tableView.reloadData()
        }
    }

    @objc
    private func fetchData() {
        if isRefreshing { return }
        isRefreshing = true
        AF.request(
            baseURL
                .appendingPathComponent("topics")
                .appendingPathComponent(String(topic?.id ?? 0))
                .appendingPathExtension("json")
        )
        .responseJSON { response in
            if self.tableView.refreshControl?.isRefreshing ?? false {
                self.replies = nil
            }
            if 200..<300 ~= response.response?.statusCode ?? 0 {
                self.topic = try? Topic(json: response.value ?? [:])
            } else {
                self.networkErrorView.isHidden = false
            }
            self.tableView.reloadData()
            self.isRefreshing = false
            if 200..<300 ~= response.response?.statusCode ?? 0 {
                self.fetchReplies()
            }
        }
    }

    internal func fetchReplies() {
        if replies != nil { return }
        if isRefreshing { return }
        isRefreshing = true
        AF.request(
            baseURL
                .appendingPathComponent("topics")
                .appendingPathComponent(String(topic?.id ?? 0))
                .appendingPathComponent("replies")
                .appendingPathExtension("json"),
            parameters: [
                "limit": 1_000,
            ]
        )
        .responseJSON { response in
            if 200..<300 ~= response.response?.statusCode ?? 0 {
                self.replies = try? [Reply](json: response.value ?? [])
                self.tableView.reloadSections(IndexSet([2]), with: .none)
            } else {
                self.networkErrorView.isHidden = false
            }
            self.isRefreshing = false
        }
    }

    private func didSetRefreshing() {
        if isRefreshing {
            networkErrorView.isHidden = true
            if tableView.refreshControl?.isRefreshing ?? false { return }
            activityIndicatorView.startAnimating()
        } else {
            tableView.refreshControl?.endRefreshing()
            activityIndicatorView.stopAnimating()
        }
    }

    private func didSetTopic() {
        bodyCell = TopicBodyCell()

        userActivity?.webpageURL = baseURL
            .appendingPathComponent("topics")
            .appendingPathComponent(String(topic?.id ?? 0))
    }

    private func didSetReplies() {
        replyCells = (replies ?? []).map { _ in TopicReplyCell() }
    }

    @objc
    private func action(_ barButtonItem: UIBarButtonItem) {
        guard let url = topic?.user?.avatarURL else { return }
        AF.request(url).responseImage { response in
            guard let image = response.value else { return }
            let activityItems: [Any] = [
                self.baseURL.appendingPathComponent("topics").appendingPathComponent(String(self.topic?.id ?? 0)),
                self.topic?.title ?? "",
                image,
            ]
            let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: [TUSafariActivity()])
            activityViewController.excludedActivityTypes = [.assignToContact, .copyToPasteboard, .print, .saveToCameraRoll]
            activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
            self.present(activityViewController, animated: true)
        }
    }

    private func editTopic() {
        let composeController = ComposeController()
        composeController.topic = topic
        present(UINavigationController(rootViewController: composeController), animated: true)
    }

    internal func updateTopic(_ topic: Topic?) {
        self.topic = topic
        tableView.reloadData()
    }

    private func deleteTopic() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in self.destroyTopic() })
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
        alertController.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        alertController.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero
        alertController.popoverPresentationController?.sourceView = cell
        present(alertController, animated: true)
    }

    private func destroyTopic() {
        showHUD()
        AF.request(
            baseURL
                .appendingPathComponent("topics")
                .appendingPathComponent(String(topic?.id ?? 0))
                .appendingPathExtension("json"),
            method: .delete
        )
        .responseJSON { response in
            switch response.response?.statusCode ?? 0 {
            case 200..<300:
                let topicsController = self.navigationController?.viewControllers.first as? TopicsController
                topicsController?.removeTopic(self.topic)
                self.navigationController?.popViewController(animated: true)

            case 401:
                self.showSignIn()

            default:
                self.networkError()
            }
            self.hideHUD()
        }
    }

    @objc
    private func newReply(_ sender: Any?) {
        if replies == nil { return }
        let composeController = ComposeController()
        composeController.reply = try? Reply(json: [:])
        composeController.reply?.body = sender as? String
        composeController.reply?.topicId = topic?.id
        let navigationController = UINavigationController(rootViewController: composeController)
        navigationController.modalPresentationStyle = sender is UIBarButtonItem ? .popover : .automatic
        navigationController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        present(navigationController, animated: true)
    }

    internal func addReply(_ reply: Reply) {
        replies?.append(reply)
        replyCells.append(TopicReplyCell())
        let indexPath = IndexPath(row: (replies?.count ?? 0) - 1, section: 2)
        tableView.insertRows(at: [indexPath], with: .none)
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
    }

    private func editReply(_ reply: Reply) {
        let composeController = ComposeController()
        composeController.reply = reply
        present(UINavigationController(rootViewController: composeController), animated: true)
    }

    internal func updateReply(_ reply: Reply) {
        let row = replies?.firstIndex { $0.id == reply.id } ?? 0
        replies?[row] = reply
        replyCells[row] = TopicReplyCell()
        let indexPath = IndexPath(row: row, section: 2)
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
    }

    private func deleteReply(_ indexPath: IndexPath) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "删除", style: .destructive) { _ in self.destroyReply(indexPath) })
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        let cell = tableView.cellForRow(at: indexPath)
        alertController.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        alertController.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero
        alertController.popoverPresentationController?.sourceView = cell
        present(alertController, animated: true)
    }

    private func destroyReply(_ indexPath: IndexPath) {
        let reply = replies?[indexPath.row]
        showHUD()
        AF.request(
            baseURL
                .appendingPathComponent("replies")
                .appendingPathComponent(String(reply?.id ?? 0))
                .appendingPathExtension("json"),
            method: .delete
        )
        .responseJSON { response in
            switch response.response?.statusCode ?? 0 {
            case 200..<300:
                reply?.deleted = true
                self.tableView.reloadRows(at: [indexPath], with: .none)

            case 401:
                self.showSignIn()

            default:
                self.networkError()
            }
            self.hideHUD()
        }
    }

    internal func scrollToReply(_ indexPath: IndexPath) {
        if indexPath.row >= replies?.count ?? 0 { return }
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
}

extension TopicController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 2 && replies != nil { return "回复 \(replies?.count ?? 0)" }
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [
            1,
            topic?.bodyHTML != nil ? 1 : 0,
            replies?.count ?? 0,
        ][section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: TopicTitleCell.description(), for: indexPath) as? TopicTitleCell ?? .init()
            cell.topic = topic
            return cell

        case 1:
            let cell = bodyCell ?? .init()
            cell.bodyHTML = topic?.bodyHTML
            cell.layoutIfNeeded()
            return cell

        case 2:
            let reply = replies?[indexPath.row]
            reply?.index = indexPath.row
            if reply?.deleted ?? false {
                return tableView.dequeueReusableCell(withIdentifier: TopicReplyDeletedCell.description(), for: indexPath)
            }
            let cell = replyCells[indexPath.row]
            cell.reply = reply
            cell.layoutIfNeeded()
            return cell

        default:
            return .init()
        }
    }
}

extension TopicController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        var actions: [UIContextualAction] = []
        switch indexPath.section {
        case 0:
            if topic?.abilities?.update ?? false {
                actions.append(UIContextualAction(style: .normal, title: "编辑") { _, _, completionHandler in
                    completionHandler(false)
                    self.editTopic()
                })
            }
            if topic?.abilities?.destroy ?? false {
                actions.append(UIContextualAction(style: .destructive, title: "删除") { _, _, completionHandler in
                    completionHandler(false)
                    self.deleteTopic()
                })
            }

        case 2:
            guard let reply = replies?[indexPath.row] else { break }
            if reply.deleted ?? false { return UISwipeActionsConfiguration(actions: []) }
            actions.append(UIContextualAction(style: .normal, title: "回复") { _, _, completionHandler in
                completionHandler(false)
                let reply = self.replies?[indexPath.row]
                self.newReply("#\(indexPath.row + 1)楼 @\(reply?.user?.login ?? "") ")
            })
            actions.first?.backgroundColor = tableView.tintColor
            if reply.abilities?.update ?? false {
                actions.append(UIContextualAction(style: .normal, title: "编辑") { _, _, completionHandler in
                    completionHandler(false)
                    self.editReply(reply)
                })
            }
            if reply.abilities?.destroy ?? false {
                actions.append(UIContextualAction(style: .destructive, title: "删除") { _, _, completionHandler in
                    completionHandler(false)
                    self.deleteReply(indexPath)
                })
            }

        default:
            break
        }
        let configuration = UISwipeActionsConfiguration(actions: actions.reversed())
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}
