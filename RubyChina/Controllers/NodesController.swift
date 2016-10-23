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

        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loadData)))
        view.addSubview(failureView)

        view.addSubview(loadingView)
    }

    override func viewWillAppear(_ animated: Bool) {
        if nodes.count == 0 { loadData() }
        Helper.trackView(self)
    }

    func loadData() {
        if loadingView.refreshing { return }
        failureView.hide()
        loadingView.show()
        let path = "/nodes/grouped.json"
        AFHTTPSessionManager(baseURL: Helper.baseURL).get(path, parameters: nil, progress: nil, success: { task, responseObject in
            self.loadingView.hide()
            self.nodes = self.topicsController() != nil ? [["title": "全部", "nodes": [["name": "社区"]]]] : []
            self.nodes = JSON(self.nodes.arrayValue + JSON(responseObject).arrayValue)
            self.tableView.reloadData()
            for i in 0 ..< self.nodes.count {
                for j in 0 ..< self.nodes[i]["nodes"].count {
                    let nodeId = self.nodes[i]["nodes"][j]["id"].intValue
                    if nodeId == self.topicsController()?.parameters["node_id"].intValue || nodeId == self.composeController()?.topic["node_id"].intValue { self.tableView.scrollToRow(at: IndexPath(row: j, section: i), at: .top, animated: false) }
                }
            }
        }) { task, error in
            self.loadingView.hide()
            self.failureView.show()
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return nodes.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nodes[section]["title"].string
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodes[section]["nodes"].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let node = nodes[indexPath.section]["nodes"][indexPath.row]
        cell.accessoryType = topicsController()?.parameters["node_id"].intValue == node["id"].intValue || composeController()?.topic["node_id"].intValue == node["id"].intValue ? .checkmark : .none
        cell.textLabel?.text = node["name"].string
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let node = nodes[indexPath.section]["nodes"][indexPath.row]
        topicsController()?.selectNode(node)
        composeController()?.selectNode(node)
    }

    func topicsController() -> TopicsController? {
        return navigationController?.viewControllers.filter { ($0 as? TopicsController) != nil }.last as? TopicsController
    }

    func composeController() -> ComposeController? {
        return navigationController?.viewControllers.filter { ($0 as? ComposeController) != nil }.last as? ComposeController
    }
}
