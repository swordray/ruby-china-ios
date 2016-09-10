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
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "UserIcon"), style: .Plain, target: self, action: #selector(user))
        navigationItem.title = "社区"
        view.backgroundColor = Helper.backgroundColor

        tableView.allowsMultipleSelection = false
        tableView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        tableView.backgroundColor = .clearColor()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = view.bounds
        tableView.registerClass(TopicCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)

        let searchBar = UISearchBar()
        searchBar.autocapitalizationType = .None
        searchBar.autocorrectionType = .No
        searchBar.delegate = self
        searchBar.placeholder = "搜索"
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar

        topRefreshControl.addTarget(self, action: #selector(topRefresh), forControlEvents: .ValueChanged)
        tableView.addSubview(topRefreshControl)

        let bottomRefreshControl = UIRefreshControl()
        bottomRefreshControl.addTarget(self, action: #selector(bottomRefresh), forControlEvents: .ValueChanged)
        tableView.bottomRefreshControl = bottomRefreshControl

        toolbar.autoresizingMask = .FlexibleWidth
        toolbar.delegate = self
        toolbar.frame.size.width = view.bounds.width
        view.addSubview(toolbar)

        segmentedControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), forControlEvents: .ValueChanged)
        segmentedControl.autoresizingMask = [.FlexibleLeftMargin, .FlexibleRightMargin, .FlexibleTopMargin, .FlexibleBottomMargin]
        segmentedControl.frame.size.height = 28
        segmentedControl.selectedSegmentIndex = max(0, segmentedControl.selectedSegmentIndex)
        toolbar.addSubview(segmentedControl)

        failureView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(autoRefresh)))
        view.addSubview(failureView)

        view.addSubview(loadingView)

        emptyView.text = "没有帖子"
        view.addSubview(emptyView)

        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: view)
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        navigationController?.navigationBar.hideBottomHairline()
        if tableView.indexPathForSelectedRow != nil { tableView.deselectRowAtIndexPath(tableView.indexPathForSelectedRow!, animated: true) }
        traitCollectionDidChange(nil)
        if topics.count == 0 { autoRefresh() }
        Helper.trackView(self)
    }

    override func viewWillDisappear(animated: Bool) {
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
        if refreshing { tableView.bottomRefreshControl.endRefreshing(); tableView.bottomRefreshControl.hidden = true; return }
        loadData()
    }

    func stopRefresh() {
        refreshing = false
        loadingView.hide()
        topRefreshControl.endRefreshing()
        tableView.bottomRefreshControl.endRefreshing()
        tableView.bottomRefreshControl.hidden = true
    }

    func loadData() {
        if refreshing { return }
        refreshing = true
        failureView.hide()
        emptyView.hide()
        let selectedSegmentIndex = segmentedControl.selectedSegmentIndex
        parameters["limit"] = 30
        parameters["offset"].object = topics.count
        parameters["type"] = ["last_actived", "recent", "popular", "excellent"][selectedSegmentIndex]
        AFHTTPRequestOperationManager(baseURL: Helper.baseURL).GET("/topics.json", parameters: parameters.object, success: { (operation, responseObject) in
            self.stopRefresh()
            if JSON(responseObject)["topics"].count == 0 { if self.topics.count == 0 { self.emptyView.show() } else { return } }
            if self.topics.count == 0 { self.tableView.scrollRectToVisible(CGRect(x: 0, y: self.tableView.tableHeaderView?.frame.height ?? 0, width: 1, height: 1), animated: false) }
            self.topics = JSON(self.topics.arrayValue + JSON(responseObject)["topics"].arrayValue)
            self.tableView.reloadData()
            self.segmentedControl.selectedSegmentIndex = selectedSegmentIndex
        }) { (operation, error) in
            self.stopRefresh()
            self.failureView.show()
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return topics.count
    }

    func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 61
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let cell = TopicCell()
        cell.accessoryType = .DisclosureIndicator
        cell.detailTextLabel?.text = " "
        cell.frame.size.width = tableView.frame.width
        cell.textLabel?.text = topics[indexPath.row]["title"].string
        cell.topic = topics[indexPath.row]
        cell.layoutSubviews()
        let textLabelHeight = cell.textLabel!.textRectForBounds(cell.textLabel!.frame, limitedToNumberOfLines: cell.textLabel!.numberOfLines).height
        return 11.5 + textLabelHeight + 6.5 + cell.detailTextLabel!.frame.height + 11.5
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TopicCell
        cell.topic = topics[indexPath.row]
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let topicController = TopicController()
        topicController.topic = topics[indexPath.row]
        splitViewController?.showDetailViewController(UINavigationController(rootViewController: topicController), sender: self)
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if (indexPath.row + 1) % 30 == 0 && indexPath.row + 1 == topics.count { autoRefresh() }
    }

    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .Top
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        toolbar.frame.origin.y = min(UIApplication.sharedApplication().statusBarFrame.width, UIApplication.sharedApplication().statusBarFrame.height) + navigationController!.navigationBar.frame.height
        toolbar.frame.size.height = navigationController!.navigationBar.frame.height
        tableView.contentInset.top = toolbar.frame.origin.y + toolbar.frame.height
        tableView.scrollIndicatorInsets.top = toolbar.frame.origin.y + toolbar.frame.height
        segmentedControl.frame.size.width = min(320, view.bounds.width, view.bounds.height) - 16
        segmentedControl.frame.origin.x = (view.bounds.width - segmentedControl.frame.width) / 2
    }

    func segmentedControlValueChanged(segmentedControl: UISegmentedControl) {
        topics = []
        autoRefresh()
    }

    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        parameters["query"].string = searchBar.text != "" ? searchBar.text : nil
        topics = []
        tableView.reloadData()
        autoRefresh()
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.setShowsCancelButton(false, animated: true)
        searchBar.text = ""
        searchBarSearchButtonClicked(searchBar)
    }

    func user() {
        navigationController?.pushViewController(UserController(), animated: true)
    }

    func selectNode(node: JSON) {
        parameters["node_id"] = node["id"]
        title = node["name"].string
        topics = []
        tableView.reloadData()
        navigationController?.popToViewController(self, animated: true)
    }
}


extension TopicsController: UIViewControllerPreviewingDelegate {

    @available(iOS 9.0, *)
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRowAtPoint(view.convertPoint(location, toView: tableView)) else { return nil }
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) else { return nil }
        previewingContext.sourceRect = tableView.convertRect(cell.frame, toView: view)
        let topicController = TopicController()
        topicController.topic = topics[indexPath.row]
        return topicController
    }

    @available(iOS 9.0, *)
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        splitViewController?.showDetailViewController(UINavigationController(rootViewController: viewControllerToCommit), sender: self)
    }
}
