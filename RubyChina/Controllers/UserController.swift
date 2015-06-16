//
//  UserController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/29/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import AFNetworking
import MBProgressHUD
import SDWebImage
import SwiftyJSON
import UIKit

class UserController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var failureView = FailureView()
    var loadingView = LoadingView()
    var tableView = UITableView(frame: CGRect(), style: .Grouped)
    var user: JSON = [:]


    override func viewDidLoad() {
        title = "账号"
        view.backgroundColor = Helper.backgroundColor

        tableView.allowsMultipleSelection = false
        tableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        tableView.backgroundColor = .clearColor()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("loadData")))
        view.addSubview(failureView)

        view.addSubview(loadingView)
    }

    override func viewWillAppear(animated: Bool) {
        if tableView.indexPathForSelectedRow() != nil { tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow()!, animated: true) }
        loadData()
        Helper.trackView(self)
    }

    func loadData() {
        if Defaults.userId == nil { return }
        if loadingView.refreshing { return }
        failureView.hide()
        loadingView.show()
        let path = "/users/current.json"
        AFHTTPRequestOperationManager(baseURL: Helper.baseURL).GET(path, parameters: nil, success: { (operation, responseObject) in
            self.loadingView.hide()
            self.user = JSON(responseObject)["user"]
            if self.user.dictionary == nil { self.signedOut() }
            self.tableView.reloadData()
        }) { (operation, error) in
            self.loadingView.hide()
            self.failureView.show()
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Defaults.userId != nil ? 3 : 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 4
        case 2: return 1
        default: return 0
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 && Defaults.userId != nil { return 64 }
        return tableView.rowHeight
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if Defaults.userId == nil {
                let cell = UITableViewCell()
                cell.accessoryType = .DisclosureIndicator
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
                cell.accessoryType = .DisclosureIndicator
                cell.textLabel?.text = "节点"
                return cell
            case 1:
                let cell = UITableViewCell()
                cell.accessoryType = .DisclosureIndicator
                cell.textLabel?.text = "发帖"
                return cell
            case 2:
                let cell = UITableViewCell()
                cell.accessoryType = .DisclosureIndicator
                cell.textLabel?.text = "反馈"
                return cell
            case 3:
                let cell = UITableViewCell(style: .Value1, reuseIdentifier: nil)
                cell.detailTextLabel?.text = "\((NSURLCache.sharedURLCache().currentDiskUsage + Int(SDImageCache.sharedImageCache().getSize())) / 1024 / 1024) MB"
                cell.textLabel?.text = "缓存"
                return cell
            default: 0
            }
        case 2:
            let cell = UITableViewCell()
            cell.textLabel?.text = "注销"
            cell.textLabel?.textAlignment = .Center
            cell.textLabel?.textColor = .redColor()
            return cell
        default: 0
        }
        return UITableViewCell()
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            if Defaults.userId == nil { Helper.signIn(self); tableView.deselectRowAtIndexPath(indexPath, animated: true); return }
            let webViewController = WebViewController()
            webViewController.path = Helper.baseURL.absoluteString! + "/" + user["login"].stringValue
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
                webViewController.path = Helper.baseURL.absoluteString! + "/feedback"
                webViewController.title = "反馈"
                splitViewController?.showDetailViewController(UINavigationController(rootViewController: webViewController), sender: self)
            case 3:
                let progressHUD = MBProgressHUD.showHUDAddedTo(view, animated: false)
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    NSURLCache.sharedURLCache().removeAllCachedResponses()
                    SDImageCache.sharedImageCache().clearDisk()
                    SDImageCache.sharedImageCache().clearMemory()
                    dispatch_async(dispatch_get_main_queue()) {
                        tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                        progressHUD.labelText = "已清理"
                        progressHUD.mode = .Text
                        progressHUD.hide(true, afterDelay: 2)
                    }
                }
            default: 0
            }
        case 2:
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            let alertController = UIAlertController(title: "确定注销吗？", message: nil, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "注销", style: .Default, handler: { (_) in
                let progressHUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
                AFHTTPRequestOperationManager(baseURL: Helper.baseURL).DELETE("/sessions/0.json", parameters: nil, success: { (operation, responseObject) in
                    progressHUD.labelText = "已注销"
                    progressHUD.mode = .Text
                    progressHUD.hide(true, afterDelay: 2)
                    self.signedOut()
                }) { (operation, error) in
                    progressHUD.labelText = "网络错误"
                    progressHUD.mode = .Text
                    progressHUD.hide(true, afterDelay: 2)
                }
            }))
            presentViewController(alertController, animated: true, completion: nil)
        default: 0
        }
    }

    func signedOut() {
        Defaults.userId = nil
        user = [:]
        tableView.reloadData()
    }
}
