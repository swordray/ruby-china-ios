//
//  UserController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 6/14/19.
//  Copyright © 2019 Jianqiu Xiao. All rights reserved.
//

import Alamofire

class UserController: ViewController {

    private var activityIndicatorView: ActivityIndicatorView!
    private var isRefreshing = false { didSet { didSetRefreshing() } }
    private var networkErrorView: NetworkErrorView!
    private var noContentView: NoContentView!
    private var tableView: UITableView!
    private var topics: [Topic] = []
    private var topicsIsLoaded = false
    public  var user: User?

    override init() {
        super.init()

        navigationItem.largeTitleDisplayMode = .never
    }

    override func loadView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(fetchData), for: .valueChanged)
        tableView.register(TopicsCell.self, forCellReuseIdentifier: TopicsCell.description())
        tableView.register(UserHeaderView.self, forHeaderFooterViewReuseIdentifier: UserHeaderView.description())
        view = tableView

        activityIndicatorView = ActivityIndicatorView()
        view.addSubview(activityIndicatorView)

        networkErrorView = NetworkErrorView()
        networkErrorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(fetchData)))
        view.addSubview(networkErrorView)

        noContentView = NoContentView()
        noContentView.textLabel?.text = "无内容"
        view.addSubview(noContentView)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        additionalSafeAreaInsets.top = -(navigationController?.navigationBar.intrinsicContentSize.height ?? 0)

        tryUpdateNavigationBarBackground()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        additionalSafeAreaInsets.top = -(navigationController?.navigationBar.intrinsicContentSize.height ?? 0)

        tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: animated) }

        tryUpdateNavigationBarBackground()

        if topics.count == 0 && !topicsIsLoaded || !networkErrorView.isHidden { fetchData() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tryUpdateNavigationBarBackground()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        updateNavigationBarBackground()
    }

    @objc
    private func fetchData() {
        if activityIndicatorView.isAnimating { tableView.refreshControl?.endRefreshing() }
        if isRefreshing { return }
        isRefreshing = true
        let limit = 50
        AF.request(
            baseURL
                .appendingPathComponent("users")
                .appendingPathComponent(user?.login ?? "")
                .appendingPathComponent("topics")
                .appendingPathExtension("json"),
            parameters: [
                "limit": limit,
                "offset": tableView.refreshControl?.isRefreshing ?? false ? 0 : topics.count,
            ]
        )
        .responseJSON { response in
            if self.tableView.refreshControl?.isRefreshing ?? false {
                self.topics = []
                self.topicsIsLoaded = false
            }
            if 200..<300 ~= response.response?.statusCode ?? 0 {
                let topics = (try? [Topic](json: response.value ?? [])) ?? []
                self.topics += topics
                self.topicsIsLoaded = topics.count < limit
                self.noContentView.isHidden = self.topics.count > 0
            } else {
                self.networkErrorView.isHidden = false
            }
            self.tableView.reloadData()
            self.isRefreshing = false
        }
    }

    private func didSetRefreshing() {
        if isRefreshing {
            networkErrorView.isHidden = true
            noContentView.isHidden = true
            if tableView.refreshControl?.isRefreshing ?? false { return }
            activityIndicatorView.startAnimating()
        } else {
            tableView.refreshControl?.endRefreshing()
            activityIndicatorView.stopAnimating()
        }
    }

    private func updateNavigationBarBackground() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        let headerView = tableView.headerView(forSection: 0)
        let alpha = self != navigationController?.topViewController || headerView == nil ? 1 : (tableView.contentOffset.y + view.safeAreaInsets.top) / ((headerView?.frame.height ?? 0) - navigationBar.frame.height)
        navigationBar.subviews.first { $0.classForCoder.description() == "_UIBarBackground" }?.alpha = max(0, min(1, alpha))
        navigationItem.title = alpha < 1 ? nil : user?.login
    }

    private func tryUpdateNavigationBarBackground() {
        for interval in [0.001, 0.01, 0.1] {
            DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
                self.updateNavigationBarBackground()
            }
        }
    }
}

extension UserController: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self != navigationController?.topViewController { return }
        updateNavigationBarBackground()
    }
}

extension UserController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topics.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: UserHeaderView.description()) as? UserHeaderView
        view?.user = user
        return view
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TopicsCell.description(), for: indexPath) as? TopicsCell ?? .init()
        cell.topic = topics[indexPath.row]
        return cell
    }
}

extension UserController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !topicsIsLoaded && indexPath.row == topics.count - 1 { fetchData() }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let topicController = TopicController()
        topicController.topic = topics[indexPath.row]
        navigationController?.pushViewController(topicController, animated: true)
    }
}
