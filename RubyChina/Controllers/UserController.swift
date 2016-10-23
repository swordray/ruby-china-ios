//
//  UserController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/29/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import AFNetworking
import MBProgressHUD
import SwiftyJSON
import UIKit

class UserController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var failureView = FailureView()
    var loadingView = LoadingView()
    var tableView = UITableView(frame: CGRect(), style: .grouped)
    var user: JSON = [:]


    override func viewDidLoad() {
        title = "账号"
        view.backgroundColor = Helper.backgroundColor

        tableView.allowsMultipleSelection = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loadData)))
        view.addSubview(failureView)

        view.addSubview(loadingView)
    }

    override func viewWillAppear(_ animated: Bool) {
        if let indexPath = tableView.indexPathForSelectedRow { tableView.deselectRow(at: indexPath, animated: true) }
        loadData()
        Helper.trackView(self)
    }

    func loadData() {
        if Defaults.userId == nil { return }
        if loadingView.refreshing { return }
        failureView.hide()
        loadingView.show()
        let path = "/users/current.json"
        AFHTTPSessionManager(baseURL: Helper.baseURL).get(path, parameters: nil, progress: nil, success: { task, responseObject in
            self.loadingView.hide()
            self.user = JSON(responseObject)["user"]
            if self.user.dictionary == nil { self.signedOut() }
            self.tableView.reloadData()
        }) { task, error in
            self.loadingView.hide()
            self.failureView.show()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Defaults.userId != nil ? 3 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 4
        case 2: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && Defaults.userId != nil { return 11.5 + 44 + 11.5 }
        return tableView.rowHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if Defaults.userId == nil {
                let cell = UITableViewCell()
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "登录"
                return cell
            }
            let cell = UserNameCell()
            cell.separatorInset.left = tableView.separatorInset.left
            cell.user = user
            return cell
        case 1:
            switch indexPath.row {
            case 0:
                let cell = UITableViewCell()
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "节点"
                return cell
            case 1:
                let cell = UITableViewCell()
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "发帖"
                return cell
            case 2:
                let cell = UITableViewCell()
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.text = "反馈"
                return cell
            case 3:
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.detailTextLabel?.text = "\(URLCache.shared.currentDiskUsage / 1024 / 1024) MB"
                cell.textLabel?.text = "缓存"
                return cell
            default: Void()
            }
        case 2:
            let cell = UITableViewCell()
            cell.textLabel?.text = "注销"
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.textColor = .red
            return cell
        default: Void()
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            if Defaults.userId == nil { signIn(); tableView.deselectRow(at: indexPath, animated: true); return }
            let webViewController = WebViewController()
            webViewController.path = "\(Helper.baseURL.absoluteString)/\(user["login"])"
            webViewController.title = user["login"].string
            splitViewController?.showDetailViewController(UINavigationController(rootViewController: webViewController), sender: self)
        case 1:
            switch indexPath.row {
            case 0:
                navigationController?.pushViewController(NodesController(), animated: true)
            case 1:
                splitViewController?.showDetailViewController(UINavigationController(rootViewController: ComposeController()), sender: self)
            case 2:
                let webViewController = WebViewController()
                webViewController.path = "\(Helper.baseURL.absoluteString)/feedback"
                webViewController.title = "反馈"
                splitViewController?.showDetailViewController(UINavigationController(rootViewController: webViewController), sender: self)
            case 3:
                let progressHUD = MBProgressHUD.showAdded(to: view, animated: false)
                DispatchQueue.global().async {
                    URLCache.shared.removeAllCachedResponses()
                    DispatchQueue.main.async {
                        tableView.reloadRows(at: [indexPath], with: .automatic)
                        progressHUD.hide(animated: false)
                        self.alert("已清理")
                    }
                }
            default: Void()
            }
        case 2:
            tableView.deselectRow(at: indexPath, animated: true)
            let alertController = UIAlertController(title: "确定注销吗？", message: "注销后可以重新登录。", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "注销", style: .destructive) { _ in
                let progressHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
                let path = "/sessions/0.json"
                AFHTTPSessionManager(baseURL: Helper.baseURL).delete(path, parameters: nil, success: { task, responseObject in
                    progressHUD.hide(animated: false)
                    self.signedOut()
                }) { task, error in
                    progressHUD.hide(animated: false)
                    self.alert("网络错误")
                }
            })
            present(alertController, animated: true, completion: nil)
        default: Void()
        }
    }

    func signedOut() {
        Defaults.userId = nil
        user = [:]
        tableView.reloadData()
    }
}
