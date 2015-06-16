//
//  NodesController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/28/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import AFNetworking
import SwiftyJSON
import UIKit

class NodesController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var failureView = FailureView()
    var loadingView = LoadingView()
    var nodes: JSON = []
    var tableView = UITableView()


    override func viewDidLoad() {
        navigationItem.title = "节点"
        view.backgroundColor = Helper.backgroundColor

        tableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        tableView.backgroundColor = .clearColor()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("loadData")))
        view.addSubview(failureView)

        view.addSubview(loadingView)
    }

    override func viewWillAppear(animated: Bool) {
        if nodes.count == 0 { loadData() }
        Helper.trackView(self)
    }

    func loadData() {
        if loadingView.refreshing { return }
        failureView.hide()
        loadingView.show()
        AFHTTPRequestOperationManager(baseURL: Helper.baseURL).GET("/nodes/grouped.json", parameters: nil, success: { (operation, responseObject) in
            self.loadingView.hide()
            self.nodes = self.topicsController() != nil ? [["title": "全部", "nodes": [["name": JSON(NSBundle.mainBundle().localizedInfoDictionary!)["CFBundleDisplayName"].stringValue]]]] : []
            self.nodes = JSON(self.nodes.arrayValue + JSON(responseObject).arrayValue)
            self.tableView.reloadData()
        }) { (operation, error) in
            self.loadingView.hide()
            self.failureView.show()
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return nodes.count
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nodes[section]["title"].string
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes[section]["nodes"].count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        let node = nodes[indexPath.section]["nodes"][indexPath.row]
        cell.accessoryType = topicsController()?.parameters["node_id"].intValue == node["id"].intValue || composeController()?.topic["node_id"].intValue == node["id"].intValue ? .Checkmark : .None
        cell.textLabel?.text = node["name"].string
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let node = nodes[indexPath.section]["nodes"][indexPath.row]
        topicsController()?.selectNode(node)
        composeController()?.selectNode(node)
    }

    func topicsController() -> TopicsController? {
        return navigationController?.viewControllers.filter({ ($0 as? TopicsController) != nil }).last as? TopicsController
    }

    func composeController() -> ComposeController? {
        return navigationController?.viewControllers.filter({ ($0 as? ComposeController) != nil }).last as? ComposeController
    }
}
