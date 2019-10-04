//
//  SignInController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import Alamofire

class SignInController: ViewController {

    private var passwordField: UITextField!
    private var tableView: UITableView!
    private var usernameField: UITextField!

    override init() {
        super.init()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismiss))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(action))

        title = "登录"
    }

    override func loadView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.dataSource = self
        tableView.delegate = self
        view = tableView

        usernameField = UITextField()
        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no
        usernameField.clearButtonMode = .whileEditing
        usernameField.delegate = self
        usernameField.font = .preferredFont(forTextStyle: .body)
        usernameField.placeholder = "帐号"
        usernameField.returnKeyType = .next
        usernameField.textContentType = .username

        passwordField = UITextField()
        passwordField.clearButtonMode = .whileEditing
        passwordField.delegate = self
        passwordField.font = .preferredFont(forTextStyle: .body)
        passwordField.isSecureTextEntry = true
        passwordField.placeholder = "密码"
        passwordField.returnKeyType = .join
        passwordField.textContentType = .password
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        usernameField.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.preferredContentSize = tableView.contentSize
    }

    private func signIn() {
        view.endEditing(true)
        showHUD()
        let username = usernameField.text ?? ""
        let password = passwordField.text ?? ""
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
                SecAddSharedWebCredential((self.baseURL.host ?? "") as CFString, username as CFString, password as CFString) { _ in }
                self.dismiss(animated: true)
                let topicsController = (self.presentingViewController as? UINavigationController)?.viewControllers.first as? TopicsController
                topicsController?.updateRightBarButtonItem()
                topicsController?.refetchData()

            case 401:
                let alertController = UIAlertController(title: "帐号或密码错误", message: nil, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "好", style: .default))
                self.present(alertController, animated: true)

            default:
                self.networkError()
            }
            self.hideHUD()
        }
    }

    @objc
    private func action() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        [("注册", "account/sign_up"), ("忘记密码", "account/password/new")].forEach { title, pathComponent in
            alertController.addAction(UIAlertAction(title: title, style: .default) { _ in
                let webViewController = WebViewController()
                webViewController.title = title
                webViewController.url = self.baseURL.appendingPathComponent(pathComponent)
                self.navigationController?.pushViewController(webViewController, animated: true)
            })
        }
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alertController, animated: true)
    }
}

extension SignInController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [2, 1][section]
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = UITableViewCell()
            cell.selectionStyle = .none
            cell.textLabel?.text = " "
            let textField = [usernameField, passwordField][indexPath.row] ?? .init()
            cell.contentView.addSubview(textField)
            textField.snp.makeConstraints { $0.edges.equalTo(cell.textLabel ?? .init()) }
            return cell

        case 1:
            let cell = UITableViewCell()
            cell.textLabel?.text = "登录"
            cell.textLabel?.textColor = tableView.tintColor
            return cell

        default:
            return .init()
        }
    }
}

extension SignInController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            tableView.deselectRow(at: indexPath, animated: true)
            signIn()
        }
    }
}

extension SignInController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case usernameField:
            passwordField.becomeFirstResponder()

        case passwordField:
            signIn()

        default:
            break
        }
        return false
    }
}
