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
    private var notFoundView: NotFoundView!
    private var segmentedControl: UISegmentedControl!
    private var tableView: UITableView!
    private var toolbar: UIToolbar!
    private var topics: [Topic] = []
    private var topicsIsLoaded = false

    override init() {
        super.init()

        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(showNodes)),
            UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(newTopic)),
        ]

        title = "社区"
    }

    override func loadView() {
        tableView = UITableView()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(fetchData), for: .valueChanged)
        tableView.register(TopicsCell.self, forCellReuseIdentifier: TopicsCell.description())
        tableView.tableFooterView = UIView()
        view = tableView

        activityIndicatorView = ActivityIndicatorView()
        view.addSubview(activityIndicatorView)

        networkErrorView = NetworkErrorView()
        networkErrorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(fetchData)))
        view.addSubview(networkErrorView)

        notFoundView = NotFoundView()
        notFoundView.textLabel?.text = "没有帖子"
        view.addSubview(notFoundView)

        segmentedControl = UISegmentedControl(items: ["默认", "最新", "热门", "精华"])
        segmentedControl.addTarget(self, action: #selector(refetchData), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = 0

        toolbar = UIToolbar()
        toolbar.delegate = self
        toolbar.items = [UIBarButtonItem(customView: segmentedControl)]
        view.addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.leading.width.equalToSuperview()
            make.bottom.equalTo(view.snp.top)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true

        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }

        tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: animated) }

        updateRightBarButtonItem()

        if topics.count == 0 && !topicsIsLoaded || !networkErrorView.isHidden { fetchData() }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass {
            toolbar.invalidateIntrinsicContentSize()
            tableView.contentInset.top = toolbar.intrinsicContentSize.height
        }
    }

    @objc
    private func fetchData() {
        if activityIndicatorView.isAnimating { tableView.refreshControl?.endRefreshing() }
        if isRefreshing { return }
        isRefreshing = true
        let limit = 50
        Alamofire.request(
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
                self.notFoundView.isHidden = self.topics.count > 0
            } else {
                self.networkErrorView.isHidden = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.fetchData()
                }
            }
            self.tableView.reloadData()
            self.isRefreshing = false
        }
    }

    private func didSetRefreshing() {
        if isRefreshing {
            networkErrorView.isHidden = true
            notFoundView.isHidden = true
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
        title = node?.name ?? "社区"
        refetchData()
    }

    @objc
    private func showNodes(_ barButtonItem: UIBarButtonItem) {
        if isRefreshing { return }
        let navigationController = UINavigationController(rootViewController: NodesController())
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.backgroundColor = UIColor(displayP3Red: 248 / 255.0, green: 248 / 255.0, blue: 248 / 255.0, alpha: 1)
        navigationController.popoverPresentationController?.barButtonItem = barButtonItem
        present(navigationController, animated: true)
    }

    @objc
    private func newTopic() {
        let composeController = ComposeController()
        composeController.topic = try? Topic(json: [:])
        composeController.topic?.nodeId = node?.id
        composeController.topic?.nodeName = node?.name
        showDetailViewController(UINavigationController(rootViewController: composeController), sender: nil)
    }

    @objc
    private func showUser() {
        showDetailViewController(UINavigationController(rootViewController: UserController()), sender: nil)
    }

    @objc
    internal func signIn() {
        showHUD()
        SecRequestSharedWebCredential(nil, nil) { credentials, error in
            DispatchQueue.main.async {
                self.hideHUD()
                guard let credentials = credentials, error == nil, CFArrayGetCount(credentials) > 0 else { self.showSignIn(); return }
                let credential = unsafeBitCast(CFArrayGetValueAtIndex(credentials, 0), to: CFDictionary.self)
                let account = unsafeBitCast(CFDictionaryGetValue(credential, Unmanaged.passUnretained(kSecAttrAccount).toOpaque()), to: CFString.self) as String
                let password = unsafeBitCast(CFDictionaryGetValue(credential, Unmanaged.passUnretained(kSecSharedPassword).toOpaque()), to: CFString.self) as String
                self.signInAs(username: account, password: password)
            }
        }
    }

    private func signInAs(username: String, password: String) {
        showHUD()
        Alamofire.request(
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

    override func showSignIn() {
        let navigationController = UINavigationController(rootViewController: SignInController())
        navigationController.modalPresentationStyle = .popover
        navigationController.popoverPresentationController?.backgroundColor = UIColor(displayP3Red: 248 / 255.0, green: 248 / 255.0, blue: 248 / 255.0, alpha: 1)
        navigationController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(navigationController, animated: true)
    }

    internal func updateRightBarButtonItem() {
        if let url = User.current?.avatarURL {
            let imageView = UIImageView()
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showUser)))
            imageView.af_setImage(withURL: url)
            imageView.backgroundColor = .white
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            imageView.layer.cornerRadius = 14
            imageView.snp.makeConstraints { $0.size.equalTo(28) }
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: imageView)
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "UIBarButtonItemUser"), style: .plain, target: self, action: #selector(signIn))
        }
    }

    internal func removeTopic(_ topic: Topic?) {
        guard let row = topics.index(where: { $0.id == topic?.id }) else { return }
        topics.remove(at: row)
        let indexPath = IndexPath(row: row, section: 0)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    private func viewControllerForRow(at indexPath: IndexPath) -> UIViewController {
        let topicController = TopicController()
        topicController.topic = topics[indexPath.row]
        return topicController
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
        showDetailViewController(UINavigationController(rootViewController: viewControllerForRow(at: indexPath)), sender: nil)
    }
}

extension TopicsController: UIToolbarDelegate {

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .top
    }
}

extension TopicsController: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        previewingContext.sourceRect = cell.frame
        return viewControllerForRow(at: indexPath)
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        showDetailViewController(UINavigationController(rootViewController: viewControllerToCommit), sender: nil)
    }
}
