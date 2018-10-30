//
//  ComposeController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import Alamofire

class ComposeController: ViewController {

    private var activityIndicatorView: ActivityIndicatorView!
    private var bodyView: UITextView!
    private var isRefreshing = false { didSet { didSetRefreshing() } }
    private var networkErrorView: NetworkErrorView!
    public  var reply: Reply?
    private var tableView: UITableView?
    private var tableViewObservation: NSKeyValueObservation?
    private var titleField: UITextField?
    public  var topic: Topic?

    override init() {
        super.init()

        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
    }

    override func loadView() {
        tableView = topic != nil ? UITableView() : nil
        tableView?.cellLayoutMarginsFollowReadableWidth = true
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.isScrollEnabled = false
        tableView?.tableFooterView = UIView()

        tableViewObservation = tableView?.observe(\.contentSize, options: .new) { tableView, _ in
            self.bodyView.snp.updateConstraints { make in
                make.top.equalTo(self.view.safeAreaLayoutGuide).offset(tableView.contentSize.height)
            }
        }

        view = tableView ?? UIView()
        view.backgroundColor = .white

        activityIndicatorView = ActivityIndicatorView()
        view.addSubview(activityIndicatorView)

        networkErrorView = NetworkErrorView()
        networkErrorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(fetchData)))
        view.addSubview(networkErrorView)

        titleField = topic != nil ? UITextField() : nil
        titleField?.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        titleField?.clearButtonMode = .whileEditing
        titleField?.delegate = self
        titleField?.font = .preferredFont(forTextStyle: .body)
        titleField?.placeholder = "标题"
        titleField?.returnKeyType = .next
        titleField?.text = topic?.title

        bodyView = UITextView()
        bodyView.contentInset = UIEdgeInsets(top: 3, left: -5, bottom: 3, right: -5)
        bodyView.delegate = self
        bodyView.font = .preferredFont(forTextStyle: .body)
        bodyView.placeholder = "内容"
        bodyView.placeholderColor = UIColor(displayP3Red: 199 / 255, green: 199 / 255, blue: 204 / 255, alpha: 1)
        bodyView.text = topic?.body ?? reply?.body
        view.addSubview(bodyView)
        bodyView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view.readableContentGuide)
            make.top.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.navigationBar.prefersLargeTitles = true

        navigationItem.leftBarButtonItem = self == navigationController?.viewControllers.first ? splitViewController?.displayModeButtonItem : nil

        title = topic != nil ? (topic?.id == nil ? "发帖" : "编辑") : (reply?.id == nil ? "回复" : "编辑")

        tableView?.indexPathsForSelectedRows?.forEach { tableView?.deselectRow(at: $0, animated: animated) }

        fetchData()
    }

    @objc
    private func fetchData() {
        if reply?.id == nil || reply?.body != nil { return automaticallyBecomeFirstResponder() }
        if isRefreshing { return }
        isRefreshing = true
        Alamofire.request(
            baseURL
                .appendingPathComponent("replies")
                .appendingPathComponent(String(reply?.id ?? 0))
                .appendingPathExtension("json")
        )
        .responseJSON { response in
            if 200..<300 ~= response.response?.statusCode ?? 0 {
                self.reply = try? Reply(json: response.value ?? [:])
                self.bodyView.text = self.reply?.body
                self.automaticallyBecomeFirstResponder()
            } else {
                self.networkErrorView.isHidden = false
            }
            self.isRefreshing = false
        }
    }

    private func didSetRefreshing() {
        if isRefreshing {
            networkErrorView.isHidden = true
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }

    internal func setNode(_ node: Node?) {
        topic?.nodeId = node?.id
        topic?.nodeName = node?.name
        tableView?.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        automaticallyBecomeFirstResponder()
    }

    private func automaticallyBecomeFirstResponder() {
        if topic != nil && topic?.nodeId == nil {
        } else if topic != nil && topic?.title ?? "" == "" {
            titleField?.becomeFirstResponder()
        } else {
            bodyView.becomeFirstResponder()
        }
    }

    @objc
    private func keyboardWillChange(_ notification: Notification) {
        let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
        additionalSafeAreaInsets.bottom = notification.name == UIResponder.keyboardWillShowNotification ? frame.height - view.safeAreaInsets.bottom : 0
    }

    @objc
    private func textFieldDidChange(_ textField: UITextField) {
        topic?.title = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @objc
    private func done(_ barButtonItem: UIBarButtonItem) {
        if topic != nil && topic?.nodeId == nil {
            show(NodesController(), sender: nil)
        } else if topic != nil && topic?.title ?? "" == "" {
            titleField?.becomeFirstResponder()
        } else if topic?.body ?? reply?.body ?? "" == "" {
            bodyView.becomeFirstResponder()
        } else if User.current == nil {
            showSignIn(barButtonItem)
        } else {
            let alertController = UIAlertController(title: "\(title ?? "")吗？", message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
            alertController.addAction(UIAlertAction(title: title, style: .default) { _ in self.save() })
            alertController.preferredAction = alertController.actions.last
            present(alertController, animated: true)
        }
    }

    private func save() {
        view.endEditing(true)
        showHUD()
        var pathComponent = ""
        var method: HTTPMethod = .post
        if topic != nil {
            if topic?.id == nil {
                pathComponent = "topics"
                method = .post
            } else {
                pathComponent = "topics/\(topic?.id ?? 0)"
                method = .patch
            }
        } else {
            if reply?.id == nil {
                pathComponent = "topics/\(reply?.topicId ?? 0)/replies"
                method = .post
            } else {
                pathComponent = "replies/\(reply?.id ?? 0)"
                method = .patch
            }
        }
        Alamofire.request(
            baseURL.appendingPathComponent(pathComponent).appendingPathExtension("json"),
            method: method,
            parameters: [
                "node_id": topic?.nodeId ?? [],
                "title": topic?.title ?? [],
                "body": topic?.body ?? reply?.body ?? "",
            ]
        )
        .responseJSON { response in
            switch response.response?.statusCode ?? 0 {
            case 200..<300:
                let topicController = self.navigationController?.viewControllers.compactMap { $0 as? TopicController }.last
                if self.topic != nil {
                    let topic = try? Topic(json: response.value ?? [:])
                    if self.topic?.id == nil {
                        let topicController = TopicController()
                        topicController.replies = []
                        topicController.topic = topic
                        self.navigationController?.viewControllers = [topicController]
                    } else {
                        topicController?.updateTopic(topic)
                        self.navigationController?.popViewController(animated: true)
                    }
                } else {
                    guard let reply = try? Reply(json: response.value ?? [:]) else { return }
                    if self.reply?.id == nil {
                        topicController?.addReply(reply)
                    } else {
                        topicController?.updateReply(reply)
                    }
                    self.navigationController?.popViewController(animated: true)
                }
            case 401:
                self.showSignIn()
            case 403:
                let alertController = UIAlertController(title: "当前用户没有发帖权限，具体请参考官网的相关说明", message: nil, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "好", style: .default))
                self.present(alertController, animated: true)
            default:
                self.networkError()
            }
            self.hideHUD()
        }
    }
}

extension ComposeController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = UITableViewCell()
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = topic?.nodeId != nil ? "[\(topic?.nodeName ?? "")]" : "节点"
            cell.textLabel?.textColor = topic?.nodeId != nil ? .black : bodyView.placeholderColor
            return cell
        case 1:
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.textLabel?.text = " "
            cell.contentView.addSubview(titleField ?? .init())
            titleField?.snp.makeConstraints { $0.edges.equalTo(cell.textLabel ?? .init()) }
            return cell
        default:
            return .init()
        }
    }
}

extension ComposeController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            show(NodesController(), sender: nil)
        }
    }
}

extension ComposeController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        bodyView.becomeFirstResponder()
        return false
    }
}

extension ComposeController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        topic?.body = text
        reply?.body = text
    }
}
