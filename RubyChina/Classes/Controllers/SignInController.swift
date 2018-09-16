//
//  SignInController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/29/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import AFNetworking
import MBProgressHUD
import SwiftyJSON
import TPKeyboardAvoiding
import UIKit

class SignInController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    var passwordField = UITextField()
    var tableView = TPKeyboardAvoidingTableView(frame: CGRect(), style: .grouped)
    var usernameField = UITextField()
    var viewController: UIViewController?


    override func viewDidLoad() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissNow))
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "注册", style: .plain, target: self, action: #selector(signUp)),
            UIBarButtonItem(title: "忘记密码", style: .plain, target: self, action: #selector(forgot)),
        ].reversed()
        title = "登录"
        view.backgroundColor = Helper.backgroundColor

        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no
        usernameField.clearButtonMode = .whileEditing
        usernameField.delegate = self
        usernameField.font = .preferredFont(forTextStyle: .body)
        usernameField.frame.size.height = 44
        usernameField.placeholder = "账号"
        usernameField.returnKeyType = .next

        passwordField.clearButtonMode = .whileEditing
        passwordField.delegate = self
        passwordField.font = .preferredFont(forTextStyle: .body)
        passwordField.frame.size.height = 44
        passwordField.placeholder = "密码"
        passwordField.returnKeyType = .join
        passwordField.isSecureTextEntry = true
    }

    override func viewWillAppear(_ animated: Bool) {
        Helper.trackView(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        usernameField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        view.endEditing(true)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell = UITableViewCell()
                cell.accessoryView = usernameField
                cell.frame.size.width = tableView.frame.width
                cell.selectionStyle = .none
                usernameField.frame.size.width = tableView.frame.width - tableView.separatorInset.left * 2
                return cell
            case 1:
                let cell = UITableViewCell()
                cell.accessoryView = passwordField
                cell.frame.size.width = tableView.frame.width
                cell.selectionStyle = .none
                passwordField.frame.size.width = tableView.frame.width - tableView.separatorInset.left * 2
                return cell
            default: Void()
            }
        case 1:
            let cell = UITableViewCell()
            cell.textLabel?.text = "登录"
            cell.textLabel?.textColor = Helper.tintColor
            return cell
        default: Void()
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        signIn()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameField: passwordField.becomeFirstResponder()
        case passwordField: signIn()
        default: Void()
        }
        return true
    }

    override func signIn() {
        let progressHUD = MBProgressHUD.showAdded(to: view, animated: false)
        let path = "/sessions.json"
        let parameters = [
            "username": usernameField.text!,
            "password": passwordField.text!,
        ]
        AFHTTPSessionManager(baseURL: Helper.baseURL).post(path, parameters: parameters, progress: nil, success: { task, responseObject in
            progressHUD.hide(animated: false)
            Defaults.userId = JSON(responseObject)["user"]["id"].int
            self.dismissNow()
        }) { task, error in
            progressHUD.hide(animated: false)
            self.alert((task?.response as? HTTPURLResponse)?.statusCode == 401 ? "账号或密码错误" : "网络错误")
        }
    }

    func signUp() {
        let webViewController = WebViewController()
        webViewController.path = "\(Helper.baseURL.absoluteString)/account/sign_up"
        webViewController.title = "注册"
        navigationController?.pushViewController(webViewController, animated: true)
    }

    func forgot() {
        let webViewController = WebViewController()
        webViewController.path = "\(Helper.baseURL.absoluteString)/account/password/new"
        webViewController.title = "忘记密码"
        navigationController?.pushViewController(webViewController, animated: true)
    }

    func dismissNow() {
        dismiss(animated: true, completion: nil)
        viewController?.viewWillAppear(false)
    }
}
