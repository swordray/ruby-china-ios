//
//  TopicsController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import Alamofire

class TopicsController: ViewController {

    private var activityIndicatorView: ActivityIndicatorView!
    private var isRefreshing = false { didSet { didSetRefreshing() } }
    private var networkErrorView: NetworkErrorView!
    public  var node: Node? { didSet { didSetNode(oldValue) } }
    private var noContentView: NoContentView!
    private var segmentedControl: UISegmentedControl!
    private var tableView: UITableView!
    private var topics: [Topic] = []
    private var topicsIsLoaded = false

    override init() {
        super.init()

        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: self, action: #selector(showNodes)),
            UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newTopic)),
        ]

        title = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
    }

    override func loadView() {
        tableView = UITableView()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(fetchData), for: .valueChanged)
        tableView.register(TopicsCell.self, forCellReuseIdentifier: TopicsCell.description())
        tableView.tableHeaderView = UIView()
        tableView.tableHeaderView?.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(44)
        }
        tableView.tableFooterView = UIView()
        view = tableView

        activityIndicatorView = ActivityIndicatorView()
        view.addSubview(activityIndicatorView)

        networkErrorView = NetworkErrorView()
        networkErrorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(fetchData)))
        view.addSubview(networkErrorView)

        noContentView = NoContentView()
        noContentView.textLabel?.text = "无内容"
        view.addSubview(noContentView)

        segmentedControl = UISegmentedControl(items: ["默认", "最新", "热门", "精华"])
        segmentedControl.addTarget(self, action: #selector(refetchData), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0
        tableView.tableHeaderView?.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalTo(view.layoutMarginsGuide)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true

        tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: animated) }

        updateRightBarButtonItem()

        if topics.count == 0 && !topicsIsLoaded || !networkErrorView.isHidden { fetchData() }
    }

    @objc
    private func fetchData() {
        if activityIndicatorView.isAnimating { tableView.refreshControl?.endRefreshing() }
        if isRefreshing { return }
        isRefreshing = true
        let limit = 50
        AF.request(
            baseURL.appendingPathComponent("topics").appendingPathExtension("json"),
            parameters: [
                "type": ["last_actived", "recent", "popular", "excellent"][segmentedControl.selectedSegmentIndex],
                "node_id": node?.id ?? [],
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
            segmentedControl.isEnabled = false
            if tableView.refreshControl?.isRefreshing ?? false { return }
            activityIndicatorView.startAnimating()
        } else {
            segmentedControl.isEnabled = true
            tableView.refreshControl?.endRefreshing()
            activityIndicatorView.stopAnimating()
        }
    }

    @objc
    internal func refetchData() {
        topics = []
        topicsIsLoaded = false
        tableView.reloadData()
        fetchData()
    }

    private func didSetNode(_ oldValue: Node?) {
        if node?.id == oldValue?.id { return }
        title = node?.name ?? Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
        refetchData()
    }

    @objc
    private func showNodes(_ barButtonItem: UIBarButtonItem) {
        if isRefreshing { return }
        let navigationController = UINavigationController(rootViewController: NodesController())
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.barButtonItem = barButtonItem
        present(navigationController, animated: true)
    }

    @objc
    private func newTopic(_ barButtonItem: UIBarButtonItem) {
        let composeController = ComposeController()
        composeController.topic = Topic()
        composeController.topic?.nodeId = node?.id
        composeController.topic?.nodeName = node?.name
        let navigationController = UINavigationController(rootViewController: composeController)
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.barButtonItem = barButtonItem
        present(navigationController, animated: true)
    }

    @objc
    private func showAccount() {
        navigationController?.pushViewController(AccountController(), animated: true)
    }

    @objc
    internal func signIn(_ barButtonItem: UIBarButtonItem? = nil) {
        showHUD()
        SecRequestSharedWebCredential(nil, nil) { credentials, error in
            DispatchQueue.main.async {
                self.hideHUD()
                guard let credentials = credentials, error == nil, CFArrayGetCount(credentials) > 0 else { self.showSignIn(barButtonItem); return }
                let credential = unsafeBitCast(CFArrayGetValueAtIndex(credentials, 0), to: CFDictionary.self)
                let account = unsafeBitCast(CFDictionaryGetValue(credential, Unmanaged.passUnretained(kSecAttrAccount).toOpaque()), to: CFString.self) as String
                let password = unsafeBitCast(CFDictionaryGetValue(credential, Unmanaged.passUnretained(kSecSharedPassword).toOpaque()), to: CFString.self) as String
                self.signInAs(username: account, password: password)
            }
        }
    }

    private func signInAs(username: String, password: String) {
        showHUD()
        AF.request(
            baseURL.appendingPathComponent("sessions").appendingPathExtension("json"),
            method: .post,
            parameters: [
                "username": username,
                "password": password,
            ]
        )
        .responseJSON { response in
            switch response.response?.statusCode ?? 0 {
            case 200..<300:
                User.current = try? User(json: response.value ?? [:])
                self.updateRightBarButtonItem()
                self.refetchData()

            default:
                self.showSignIn()
            }
            self.hideHUD()
        }
    }

    internal func updateRightBarButtonItem() {
        if User.current == nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "person.crop.circle"), style: .plain, target: self, action: #selector(signIn))
        } else {
            let imageView = UIImageView()
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showAccount)))
            imageView.backgroundColor = .secondarySystemBackground
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            imageView.layer.cornerRadius = 14
            imageView.setImage(withURL: User.current?.avatarURL)
            imageView.snp.makeConstraints { $0.size.equalTo(28) }
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: imageView)
        }
    }

    internal func removeTopic(_ topic: Topic?) {
        guard let row = topics.firstIndex(where: { $0.id == topic?.id }) else { return }
        topics.remove(at: row)
        let indexPath = IndexPath(row: row, section: 0)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}

extension TopicsController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topics.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TopicsCell.description(), for: indexPath) as? TopicsCell ?? .init()
        cell.topic = topics[indexPath.row]
        return cell
    }
}

extension TopicsController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if !topicsIsLoaded && indexPath.row == topics.count - 1 { fetchData() }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let topicController = TopicController()
        topicController.topic = topics[indexPath.row]
        navigationController?.pushViewController(topicController, animated: true)
    }
}
