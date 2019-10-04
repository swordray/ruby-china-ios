//
//  AccountController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import Alamofire

class AccountController: ViewController {

    private var activityIndicatorView: ActivityIndicatorView!
    private var isRefreshing = false { didSet { didSetRefreshing() } }
    private var networkErrorView: NetworkErrorView!
    private var tableView: UITableView!
    private var user: User?

    override init() {
        super.init()

        navigationItem.largeTitleDisplayMode = .never

        title = "帐号"
    }

    override func loadView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AccountNameCell.self, forCellReuseIdentifier: AccountNameCell.description())
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.description())
        view = tableView

        activityIndicatorView = ActivityIndicatorView()
        view.addSubview(activityIndicatorView)

        networkErrorView = NetworkErrorView()
        networkErrorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(fetchData)))
        view.addSubview(networkErrorView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        user = User.current

        tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: animated) }

        fetchData()
    }

    @objc
    private func fetchData() {
        if isRefreshing { return }
        isRefreshing = true
        AF.request(
            baseURL
                .appendingPathComponent("users")
                .appendingPathComponent("current")
                .appendingPathExtension("json")
        )
        .responseJSON { response in
            if 200..<300 ~= response.response?.statusCode ?? 0 {
                if let user = try? User(json: response.value ?? [:]), user.id != nil {
                    User.current = user
                    self.user = user
                    self.tableView.reloadData()
                } else {
                    self.signedOut()
                    let topicsController = self.navigationController?.viewControllers.first as? TopicsController
                    topicsController?.signIn()
                }
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

    private func signOut() {
        showHUD()
        AF.request(
            baseURL
                .appendingPathComponent("sessions")
                .appendingPathComponent("0")
                .appendingPathExtension("json"),
            method: .delete
        )
        .responseJSON { response in
            if 200..<300 ~= response.response?.statusCode ?? 0 {
                self.signedOut()
            } else {
                self.networkError()
            }
            self.hideHUD()
        }
    }

    private func signedOut() {
        User.current = nil
        let navigationController = self.navigationController
        navigationController?.popViewController(animated: true)
        let topicsController = navigationController?.viewControllers.first as? TopicsController
        topicsController?.updateRightBarButtonItem()
        topicsController?.refetchData()
    }
}

extension AccountController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [1, 3, 1][section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: AccountNameCell.description(), for: indexPath) as? AccountNameCell ?? .init()
            cell.user = user
            return cell

        case (1, 0):
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.accessoryType = .disclosureIndicator
            cell.detailTextLabel?.text = "GitHub"
            cell.textLabel?.text = "反馈"
            return cell

        case (1, 1):
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.accessoryType = .disclosureIndicator
            let diskUsage = URLCache.shared.currentDiskUsage / 1_024 / 1_024
            cell.detailTextLabel?.text = diskUsage > 0 ? "\(diskUsage) MB" : "0"
            cell.textLabel?.text = "缓存"
            return cell

        case (1, 2):
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            let version = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? ""
            cell.detailTextLabel?.text = "\(shortVersion) (\(version))"
            cell.selectionStyle = .none
            cell.textLabel?.text = "版本"
            return cell

        case (2, 0):
            let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.description(), for: indexPath)
            cell.textLabel?.text = "退出登录"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .systemRed
            return cell

        default:
            return .init()
        }
    }
}

extension AccountController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, 0):
            let userController = UserController()
            userController.user = user
            navigationController?.pushViewController(userController, animated: true)

        case (1, 0):
            let webViewController = WebViewController()
            webViewController.title = "反馈"
            webViewController.url = baseURL.appendingPathComponent("feedback")
            navigationController?.pushViewController(webViewController, animated: true)

        case (1, 1):
            URLCache.shared.removeAllCachedResponses()
            tableView.reloadRows(at: [indexPath], with: .automatic)

        case (2, 0):
            tableView.deselectRow(at: indexPath, animated: true)
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "退出登录", style: .destructive) { _ in self.signOut() })
            alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
            let cell = tableView.cellForRow(at: indexPath)
            alertController.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            alertController.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero
            alertController.popoverPresentationController?.sourceView = cell
            present(alertController, animated: true)

        default:
            break
        }
    }
}
