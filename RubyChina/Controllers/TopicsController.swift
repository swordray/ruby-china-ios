//
//  NodesController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/22/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import AFNetworking
import CCBottomRefreshControl
import SwiftyJSON
import TPKeyboardAvoiding
import UINavigationBar_Addition
import UIKit

class TopicsController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, UIToolbarDelegate {

    var emptyView = EmptyView()
    var failureView = FailureView()
    var loadingView = LoadingView()
    var parameters: JSON = [:]
    var refreshing = false
    var segmentedControl = UISegmentedControl(items: ["默认", "最新", "热门", "精华"])
    var tableView = TPKeyboardAvoidingTableView()
    var toolbar = UIToolbar()
    var topRefreshControl = UIRefreshControl()
    var topics: JSON = []


    override func viewDidLoad() {
        automaticallyAdjustsScrollViewInsets = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "UserIcon"), style: .plain, target: self, action: #selector(user))
        navigationItem.title = "社区"
        view.backgroundColor = Helper.backgroundColor

        tableView.allowsMultipleSelection = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.register(TopicCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        let searchBar = UISearchBar()
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.delegate = self
        searchBar.placeholder = "搜索"
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar

        topRefreshControl.addTarget(self, action: #selector(topRefresh), for: .valueChanged)
        tableView.addSubview(topRefreshControl)

        let bottomRefreshControl = UIRefreshControl()
        bottomRefreshControl.addTarget(self, action: #selector(bottomRefresh), for: .valueChanged)
        tableView.bottomRefreshControl = bottomRefreshControl

        toolbar.autoresizingMask = .flexibleWidth
        toolbar.delegate = self
        toolbar.frame.size.width = view.bounds.width
        view.addSubview(toolbar)

        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        segmentedControl.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        segmentedControl.frame.size.height = 28
        segmentedControl.selectedSegmentIndex = max(0, segmentedControl.selectedSegmentIndex)
        toolbar.addSubview(segmentedControl)

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(autoRefresh)))
        view.addSubview(failureView)

        view.addSubview(loadingView)

        emptyView.text = "没有帖子"
        view.addSubview(emptyView)

        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .available {
                registerForPreviewing(with: self, sourceView: view)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.hideBottomHairline()
        if let indexPath = tableView.indexPathForSelectedRow { tableView.deselectRow(at: indexPath, animated: true) }
        traitCollectionDidChange(nil)
        if topics.count == 0 { autoRefresh() }
        Helper.trackView(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.navigationBar.showBottomHairline()
    }

    func autoRefresh() {
        if refreshing { return }
        loadingView.show()
        loadData()
    }

    func topRefresh() {
        if refreshing { topRefreshControl.endRefreshing(); return }
        topics = []
        loadData()
    }

    func bottomRefresh() {
        if refreshing { tableView.bottomRefreshControl.endRefreshing(); tableView.bottomRefreshControl.isHidden = true; return }
        loadData()
    }

    func stopRefresh() {
        refreshing = false
        loadingView.hide()
        topRefreshControl.endRefreshing()
        tableView.bottomRefreshControl.endRefreshing()
        tableView.bottomRefreshControl.isHidden = true
    }

    func loadData() {
        if refreshing { return }
        refreshing = true
        failureView.hide()
        emptyView.hide()
        let selectedSegmentIndex = segmentedControl.selectedSegmentIndex
        let path = "/topics.json"
        parameters["limit"] = 30
        parameters["offset"].object = topics.count
        parameters["type"] = ["last_actived", "recent", "popular", "excellent"][selectedSegmentIndex]
        AFHTTPSessionManager(baseURL: Helper.baseURL).get(path, parameters: parameters.object, progress: nil, success: { task, responseObject in
            self.stopRefresh()
            if JSON(responseObject)["topics"].count == 0 { if self.topics.count == 0 { self.emptyView.show() } else { return } }
            if self.topics.count == 0 { self.tableView.scrollRectToVisible(CGRect(x: 0, y: self.tableView.tableHeaderView?.frame.height ?? 0, width: 1, height: 1), animated: false) }
            self.topics = JSON(self.topics.arrayValue + JSON(responseObject)["topics"].arrayValue)
            self.tableView.reloadData()
            self.segmentedControl.selectedSegmentIndex = selectedSegmentIndex
        }) { task, error in
            self.stopRefresh()
            self.failureView.show()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topics.count
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 61
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = TopicCell()
        cell.detailTextLabel?.text = " "
        cell.frame.size.width = tableView.frame.width - 8
        cell.textLabel?.text = topics[indexPath.row]["title"].string
        cell.topic = topics[indexPath.row]
        cell.layoutSubviews()
        return 11.5 + cell.textLabel!.frame.height + 5 + cell.detailTextLabel!.frame.height + 11.5
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! TopicCell
        cell.topic = topics[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let topicController = TopicController()
        topicController.topic = topics[indexPath.row]
        splitViewController?.showDetailViewController(UINavigationController(rootViewController: topicController), sender: self)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (indexPath.row + 1) % 30 == 0 && indexPath.row + 1 == topics.count { autoRefresh() }
    }

    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .top
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        toolbar.frame.origin.y = min(UIApplication.shared.statusBarFrame.width, UIApplication.shared.statusBarFrame.height) + navigationController!.navigationBar.frame.height
        toolbar.frame.size.height = navigationController!.navigationBar.frame.height
        tableView.contentInset.top = toolbar.frame.origin.y + toolbar.frame.height
        tableView.scrollIndicatorInsets.top = toolbar.frame.origin.y + toolbar.frame.height
        segmentedControl.frame.size.width = min(320, view.bounds.width, view.bounds.height) - 16
        segmentedControl.frame.origin.x = (view.bounds.width - segmentedControl.frame.width) / 2
    }

    func segmentedControlValueChanged(_ segmentedControl: UISegmentedControl) {
        topics = []
        autoRefresh()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        parameters["query"].string = searchBar.text != "" ? searchBar.text : nil
        topics = []
        tableView.reloadData()
        autoRefresh()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        searchBarSearchButtonClicked(searchBar)
    }

    func user() {
        navigationController?.pushViewController(UserController(), animated: true)
    }

    func selectNode(_ node: JSON) {
        parameters["node_id"] = node["id"]
        title = node["name"].string
        topics = []
        tableView.reloadData()
        _ = navigationController?.popToViewController(self, animated: true)
    }
}


extension TopicsController: UIViewControllerPreviewingDelegate {

    @available(iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: view.convert(location, to: tableView)) else { return nil }
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        previewingContext.sourceRect = tableView.convert(cell.frame, to: view)
        let topicController = TopicController()
        topicController.topic = topics[indexPath.row]
        return topicController
    }

    @available(iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        splitViewController?.showDetailViewController(UINavigationController(rootViewController: viewControllerToCommit), sender: self)
    }
}
