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
        navigationItem.leftBarButtonItem = navigationController?.viewControllers.count == 1 ? splitViewController?.displayModeButtonItem() : nil
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(done))
        title = reply["topic_id"].int == nil ? (topic["id"].int == nil ? "发帖" : "编辑") : (reply["id"] == nil ? "回复" : "编辑")
        view.backgroundColor = Helper.backgroundColor

        tableView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        tableView.backgroundColor = .clearColor()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.scrollEnabled = false
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loadData)))
        view.addSubview(failureView)

        view.addSubview(loadingView)

        titleField.autocapitalizationType = .None
        titleField.autocorrectionType = .No
        titleField.clearButtonMode = .WhileEditing
        titleField.delegate = self
        titleField.frame.size.height = 44
        titleField.placeholder = "标题"
        titleField.returnKeyType = .Next
        titleField.text = topic["title"].string

        bodyTextView.autocapitalizationType = .None
        bodyTextView.autocorrectionType = .No
        bodyTextView.contentInset = UIEdgeInsets(top: -8, left: -4, bottom: -8, right: -4)
        bodyTextView.font = .systemFontOfSize(17)
        bodyTextView.placeholder = "正文"
        bodyTextView.text = topic["body"].string ?? reply["body"].string

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
    }

    override func viewWillAppear(animated: Bool) {
        tableView.deselectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: true)
        Helper.trackView(self)
    }

    override func viewDidAppear(animated: Bool) {
        loadData()
    }

    func loadData() {
        if topic["id"].int == nil && reply["id"].int == nil || topic["body"].string != nil || reply["body"].string != nil { autoBecomeFirstResponder(); return }
        if loadingView.refreshing { return }
        failureView.hide()
        loadingView.show()
        let path = topic["id"].int != nil ? "/topics/" + topic["id"].stringValue + ".json" : "/replies/" + reply["id"].stringValue + ".json"
        AFHTTPRequestOperationManager(baseURL: Helper.baseURL).GET(path, parameters: nil, success: { (operation, responseObject) in
            self.loadingView.hide()
            self.topic = JSON(responseObject)["topic"]
            self.reply = JSON(responseObject)["reply"]
            self.titleField.text = self.topic["title"].string
            self.bodyTextView.text = self.topic["body"].string ?? self.reply["body"].string
            self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .None)
            self.autoBecomeFirstResponder()
        }) { (operation, error) in
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

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row != 2 && reply["topic_id"].int != nil { return 0 }
        if indexPath.row == 2 { return tableView.frame.height - min(UIApplication.sharedApplication().statusBarFrame.width, UIApplication.sharedApplication().statusBarFrame.height) - navigationController!.navigationBar.frame.height - 44 * (reply["topic_id"].int != nil ? 0 : 2) - tableView.contentInset.bottom }
        return tableView.rowHeight
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row != 2 && reply["topic_id"].int != nil { return UITableViewCell() }
        let cell = cells[indexPath.row]
        switch indexPath.row {
        case 0:
            cell.accessoryType = .DisclosureIndicator
            cell.textLabel?.text = topic["node_name"].string != nil ? "[" + topic["node_name"].stringValue + "]" : "节点"
            cell.textLabel?.textColor = topic["node_name"].string != nil ? .blackColor() : UIColor(red: 199/255.0, green: 199/255.0, blue: 215/255.0, alpha: 1)
        case 1:
            cell.accessoryView = titleField
            cell.selectionStyle = .None
            titleField.frame.size.width = tableView.frame.width - tableView.separatorInset.left * 2
        case 2:
            cell.accessoryView = bodyTextView
            cell.selectionStyle = .None
            bodyTextView.frame.size.width = tableView.frame.width - tableView.separatorInset.left * 2
            bodyTextView.frame.size.height = self.tableView(tableView, heightForRowAtIndexPath: indexPath) - 24
        default: 0
        }
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        titleField.resignFirstResponder()
        bodyTextView.resignFirstResponder()
        navigationController?.pushViewController(NodesController(), animated: true)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        bodyTextView.becomeFirstResponder()
        return false
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        tableView.reloadData()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        keyboardVisibleHeight(notification.userInfo![UIKeyboardFrameEndUserInfoKey]!.CGRectValue.height)
    }

    func keyboardWillHide(notification: NSNotification) {
        keyboardVisibleHeight(0)
    }

    func keyboardVisibleHeight(height: CGFloat) {
        tableView.contentInset.bottom = height
        tableView.scrollIndicatorInsets.bottom = height
        cells[2].frame.size.height = self.tableView(tableView, heightForRowAtIndexPath: NSIndexPath(forRow: 2, inSection: 0))
        bodyTextView.frame.size.height = cells[2].frame.height - 24
    }

    func done() {
        if reply["topic_id"].int == nil && topic["node_id"].int == nil {
            tableView(tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
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
        let alertController = UIAlertController(title: "确定提交吗？", message: nil, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "提交", style: .Default, handler: { (_) in self.submit() }))
        presentViewController(alertController, animated: true, completion: nil)
    }

    func submit() {
        let progressHUD = MBProgressHUD.showHUDAddedTo(view, animated: false)
        let parameters = [
            "node_id": topic["node_id"].object,
            "title": titleField.text!,
            "body": bodyTextView.text!,
        ]
        let success = { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in
            progressHUD.hide(false)
            let topicController = self.navigationController?.viewControllers.filter({ ($0 as? TopicController) != nil }).last as? TopicController
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
                    self.navigationController?.popViewControllerAnimated(true)
                }
            } else {
                let reply = JSON(responseObject)["reply"]
                self.reply["id"] == nil ? topicController?.addReply(reply) : topicController?.updateReply(reply)
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
        let failure = { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            progressHUD.hide(false)
            if operation.response?.statusCode == 401 { self.signIn(); return }
            self.alert("网络错误")
        }
        if reply["topic_id"].int == nil {
            if topic["id"].int == nil {
                AFHTTPRequestOperationManager(baseURL: Helper.baseURL).POST("/topics.json", parameters: parameters, success: success, failure: failure)
            } else {
                AFHTTPRequestOperationManager(baseURL: Helper.baseURL).PATCH("/topics/" + topic["id"].stringValue + ".json", parameters: parameters, success: success, failure: failure)
            }
        } else {
            if reply["id"].int == nil {
                AFHTTPRequestOperationManager(baseURL: Helper.baseURL).POST("/topics/" + reply["topic_id"].stringValue + "/replies.json", parameters: parameters, success: success, failure: failure)
            } else {
                AFHTTPRequestOperationManager(baseURL: Helper.baseURL).PATCH("/replies/" + reply["id"].stringValue + ".json", parameters: parameters, success: success, failure: failure)
            }
        }
    }

    func selectNode(node: JSON) {
        topic["node_id"] = node["id"]
        topic["node_name"] = node["name"]
        cells[0].textLabel?.text = "[" + node["name"].stringValue + "]"
        cells[0].textLabel?.textColor = .blackColor()
        navigationController?.popToViewController(self, animated: true)
    }
}
