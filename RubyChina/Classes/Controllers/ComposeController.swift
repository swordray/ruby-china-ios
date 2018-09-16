//
//  ComposeController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/30/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import AFNetworking
import MBProgressHUD
import SZTextView
import SwiftyJSON
import UIKit

class ComposeController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    var bodyTextView = SZTextView()
    var cells = [UITableViewCell(), UITableViewCell(), UITableViewCell()]
    var failureView = FailureView()
    var loadingView = LoadingView()
    var reply: JSON = [:]
    var tableView = UITableView()
    var titleField = UITextField()
    var topic: JSON = [:]


    override func viewDidLoad() {
        navigationItem.leftBarButtonItem = navigationController?.viewControllers.count == 1 ? splitViewController?.displayModeButtonItem : nil
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        title = reply["topic_id"].int == nil ? (topic["id"].int == nil ? "发帖" : "编辑") : (reply["id"].int == nil ? "回复" : "编辑")
        view.backgroundColor = Helper.backgroundColor

        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.isScrollEnabled = false
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loadData)))
        view.addSubview(failureView)

        view.addSubview(loadingView)

        titleField.autocapitalizationType = .none
        titleField.autocorrectionType = .no
        titleField.clearButtonMode = .whileEditing
        titleField.delegate = self
        titleField.font = .preferredFont(forTextStyle: .body)
        titleField.frame.size.height = 44
        titleField.placeholder = "标题"
        titleField.returnKeyType = .next
        titleField.text = topic["title"].string

        bodyTextView.autocapitalizationType = .none
        bodyTextView.autocorrectionType = .no
        bodyTextView.contentInset = UIEdgeInsets(top: -8, left: -4, bottom: -8, right: -4)
        bodyTextView.font = .preferredFont(forTextStyle: .body)
        bodyTextView.placeholder = "正文"
        bodyTextView.text = topic["body"].string ?? reply["body"].string

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectRow(at: IndexPath(row: 0, section: 0), animated: true)
        Helper.trackView(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        loadData()
    }

    func loadData() {
        if topic["id"].int == nil && reply["id"].int == nil || topic["body"].string != nil || reply["body"].string != nil { autoBecomeFirstResponder(); return }
        if loadingView.refreshing { return }
        failureView.hide()
        loadingView.show()
        let path = topic["id"].int != nil ? "/topics/\(topic["id"]).json" : "/replies/\(reply["id"]).json"
        AFHTTPSessionManager(baseURL: Helper.baseURL).get(path, parameters: nil, progress: nil, success: { task, responseObject in
            self.loadingView.hide()
            self.topic = JSON(responseObject)["topic"]
            self.reply = JSON(responseObject)["reply"]
            self.titleField.text = self.topic["title"].string
            self.bodyTextView.text = self.topic["body"].string ?? self.reply["body"].string
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            self.autoBecomeFirstResponder()
        }) { task, error in
            self.loadingView.hide()
            self.failureView.show()
        }
    }

    func autoBecomeFirstResponder() {
        if reply["topic_id"].int != nil { bodyTextView.becomeFirstResponder() }
        else if topic["node_id"].int == nil {}
        else if titleField.text == "" { titleField.becomeFirstResponder() }
        else { bodyTextView.becomeFirstResponder() }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row != 2 && reply["topic_id"].int != nil { return 0 }
        if indexPath.row == 2 { return tableView.frame.height - min(UIApplication.shared.statusBarFrame.width, UIApplication.shared.statusBarFrame.height) - navigationController!.navigationBar.frame.height - 44 * (reply["topic_id"].int != nil ? 0 : 2) - tableView.contentInset.bottom }
        return tableView.rowHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row != 2 && reply["topic_id"].int != nil { return UITableViewCell() }
        let cell = cells[indexPath.row]
        switch indexPath.row {
        case 0:
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.text = topic["node_name"].string != nil ? "[\(topic["node_name"])]" : "节点"
            cell.textLabel?.textColor = topic["node_name"].string != nil ? .black : UIColor(red: 199/255.0, green: 199/255.0, blue: 215/255.0, alpha: 1)
        case 1:
            cell.accessoryView = titleField
            cell.selectionStyle = .none
            titleField.frame.size.width = tableView.frame.width - tableView.separatorInset.left * 2
        case 2:
            cell.accessoryView = bodyTextView
            cell.selectionStyle = .none
            bodyTextView.frame.size.width = tableView.frame.width - tableView.separatorInset.left * 2
            bodyTextView.frame.size.height = self.tableView(tableView, heightForRowAt: indexPath) - 24
        default: Void()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        titleField.resignFirstResponder()
        bodyTextView.resignFirstResponder()
        navigationController?.pushViewController(NodesController(), animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        bodyTextView.becomeFirstResponder()
        return false
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadData()
    }
    
    func keyboardWillShow(_ notification: Notification) {
        keyboardVisibleHeight((notification.userInfo![UIKeyboardFrameEndUserInfoKey]! as AnyObject).cgRectValue.height)
    }

    func keyboardWillHide(_ notification: Notification) {
        keyboardVisibleHeight(0)
    }

    func keyboardVisibleHeight(_ height: CGFloat) {
        tableView.contentInset.bottom = height
        tableView.scrollIndicatorInsets.bottom = height
        cells[2].frame.size.height = self.tableView(tableView, heightForRowAt: IndexPath(row: 2, section: 0))
        bodyTextView.frame.size.height = cells[2].frame.height - 24
    }

    func done() {
        if reply["topic_id"].int == nil && topic["node_id"].int == nil {
            tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        } else if reply["topic_id"].int == nil && titleField.text == "" {
            titleField.becomeFirstResponder()
        } else if bodyTextView.text == "" {
            bodyTextView.becomeFirstResponder()
        } else if Defaults.userId == nil {
            signIn()
        } else {
            promot()
        }
    }

    func promot() {
        tableView.endEditing(true)
        let alertController = UIAlertController(title: "确定提交吗？", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "提交", style: .default) { _ in self.submit() })
        present(alertController, animated: true, completion: nil)
    }

    func submit() {
        let progressHUD = MBProgressHUD.showAdded(to: view, animated: false)
        let parameters = [
            "node_id": topic["node_id"].object,
            "title": titleField.text!,
            "body": bodyTextView.text!,
        ]
        let success = { (task: URLSessionDataTask, responseObject: Any) -> Void in
            progressHUD.hide(animated: false)
            let topicController = self.navigationController?.viewControllers.filter { ($0 as? TopicController) != nil }.last as? TopicController
            if self.reply["topic_id"].int == nil {
                let topic = JSON(responseObject)["topic"]
                if self.topic["id"].int == nil {
                    let topicController = TopicController()
                    topicController.topic = topic
                    self.navigationController?.viewControllers = [topicController]
                } else {
                    topicController?.topic = topic
                    topicController?.title = topic["title"].string
                    topicController?.topicBodyCell = TopicBodyCell()
                    topicController?.tableView.reloadData()
                    _ = self.navigationController?.popViewController(animated: true)
                }
            } else {
                let reply = JSON(responseObject)["reply"]
                self.reply["id"].int == nil ? topicController?.addReply(reply) : topicController?.updateReply(reply)
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
        let failure = { (task: URLSessionDataTask?, error: Error) -> Void in
            progressHUD.hide(animated: false)
            if (task?.response as? HTTPURLResponse)?.statusCode == 401 { self.signIn(); return }
            self.alert("网络错误")
        }
        if reply["topic_id"].int == nil {
            if topic["id"].int == nil {
                AFHTTPSessionManager(baseURL: Helper.baseURL).post("/topics.json", parameters: parameters, progress: nil, success: success, failure: failure)
            } else {
                AFHTTPSessionManager(baseURL: Helper.baseURL).patch("/topics/\(topic["id"]).json", parameters: parameters, success: success, failure: failure)
            }
        } else {
            if reply["id"].int == nil {
                AFHTTPSessionManager(baseURL: Helper.baseURL).post("/topics/\(reply["topic_id"])/replies.json", parameters: parameters, progress: nil, success: success, failure: failure)
            } else {
                AFHTTPSessionManager(baseURL: Helper.baseURL).patch("/replies/\(reply["id"]).json", parameters: parameters, success: success, failure: failure)
            }
        }
    }

    func selectNode(_ node: JSON) {
        topic["node_id"] = node["id"]
        topic["node_name"] = node["name"]
        cells[0].textLabel?.text = "[\(node["name"])]"
        cells[0].textLabel?.textColor = .black
        _ = navigationController?.popToViewController(self, animated: true)
    }
}
