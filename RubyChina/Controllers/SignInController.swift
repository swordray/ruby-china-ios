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
    var tableView = TPKeyboardAvoidingTableView(frame: CGRect(), style: .Grouped)
    var usernameField = UITextField()
    var viewController: UIViewController?


    override func viewDidLoad() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(dismiss))
        navigationItem.rightBarButtonItems = Array([
            UIBarButtonItem(title: "注册", style: .Plain, target: self, action: #selector(signUp)),
            UIBarButtonItem(title: "忘记密码", style: .Plain, target: self, action: #selector(forgot)),
        ].reverse())
        title = "登录"
        view.backgroundColor = Helper.backgroundColor

        tableView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        tableView.backgroundColor = .clearColor()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        usernameField.autocapitalizationType = .None
        usernameField.autocorrectionType = .No
        usernameField.clearButtonMode = .WhileEditing
        usernameField.delegate = self
        usernameField.frame.size.height = 44
        usernameField.placeholder = "账号"
        usernameField.returnKeyType = .Next

        passwordField.clearButtonMode = .WhileEditing
        passwordField.delegate = self
        passwordField.frame.size.height = 44
        passwordField.placeholder = "密码"
        passwordField.returnKeyType = .Join
        passwordField.secureTextEntry = true
    }

    override func viewWillAppear(animated: Bool) {
        Helper.trackView(self)
    }

    override func viewDidAppear(animated: Bool) {
        usernameField.becomeFirstResponder()
    }

    override func viewWillDisappear(animated: Bool) {
        view.endEditing(true)
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 2
        case 1: return 1
        default: return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell = UITableViewCell()
                cell.accessoryView = usernameField
                cell.frame.size.width = tableView.frame.width
                cell.selectionStyle = .None
                usernameField.frame.size.width = tableView.frame.width - tableView.separatorInset.left * 2
                return cell
            case 1:
                let cell = UITableViewCell()
                cell.accessoryView = passwordField
                cell.frame.size.width = tableView.frame.width
                cell.selectionStyle = .None
                passwordField.frame.size.width = tableView.frame.width - tableView.separatorInset.left * 2
                return cell
            default: 0
            }
        case 1:
            let cell = UITableViewCell()
            cell.textLabel?.text = "登录"
            cell.textLabel?.textColor = Helper.tintColor
            return cell
        default: 0
        }
        return UITableViewCell()
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        signIn()
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField {
        case usernameField: passwordField.becomeFirstResponder()
        case passwordField: signIn()
        default: 0
        }
        return true
    }

    func signIn() {
        let progressHUD = MBProgressHUD.showHUDAddedTo(view, animated: false)
        let parameters = [
            "username": usernameField.text!,
            "password": passwordField.text!,
        ]
        AFHTTPRequestOperationManager(baseURL: Helper.baseURL).POST("/sessions.json", parameters: parameters, success: { (operation, responseObject) in
            progressHUD.hide(true)
            Defaults.userId = JSON(responseObject)["user"]["id"].int
            self.dismiss()
        }) { (operation, error) in
            if operation.response?.statusCode == 401 {
                progressHUD.labelText = "账号或密码错误"
                progressHUD.mode = .Text
                progressHUD.hide(true, afterDelay: 2)
                return
            }
            progressHUD.labelText = "网络错误"
            progressHUD.mode = .Text
            progressHUD.hide(true, afterDelay: 2)
        }
    }

    func signUp() {
        let webViewController = WebViewController()
        webViewController.path = Helper.baseURL.absoluteString + "/account/sign_up"
        webViewController.title = "注册"
        navigationController?.pushViewController(webViewController, animated: true)
    }

    func forgot() {
        let webViewController = WebViewController()
        webViewController.path = Helper.baseURL.absoluteString + "/account/password/new"
        webViewController.title = "忘记密码"
        navigationController?.pushViewController(webViewController, animated: true)
    }

    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
        viewController?.viewWillAppear(false)
    }
}
