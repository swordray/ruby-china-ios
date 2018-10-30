//
//  NodesController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import Alamofire

class NodesController: ViewController {

    private var activityIndicatorView: ActivityIndicatorView!
    private var isRefreshing = false { didSet { didSetRefreshing() } }
    private var networkErrorView: NetworkErrorView!
    private var sections: [Section] = []
    private var tableView: UITableView!

    override init() {
        super.init()

        navigationItem.largeTitleDisplayMode = .never

        preferredContentSize.width = UIFontMetrics.default.scaledValue(for: 220)

        title = "节点"
    }

    override func loadView() {
        tableView = UITableView()
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: UITableViewCell.description())
        tableView.tableFooterView = UIView()
        view = tableView

        activityIndicatorView = ActivityIndicatorView()
        view.addSubview(activityIndicatorView)

        networkErrorView = NetworkErrorView()
        networkErrorView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(fetchData)))
        view.addSubview(networkErrorView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.leftBarButtonItem = presentingViewController?.traitCollection.horizontalSizeClass == .compact || presentingViewController?.traitCollection.verticalSizeClass == .compact ? UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismiss)) : nil

        fetchData()
    }

    @objc
    private func fetchData() {
        if sections.count > 0 { return }
        if isRefreshing { return }
        isRefreshing = true
        Alamofire.request(
            baseURL.appendingPathComponent("sections").appendingPathExtension("json")
        ).responseJSON { response in
            if 200..<300 ~= response.response?.statusCode ?? 0 {
                self.sections = (try? [Section](json: response.value ?? [])) ?? []
                if self.topicsController != nil, let section = try? Section(json: ["name": "全部", "nodes": [["name": "社区"]]]) {
                    self.sections.insert(section, at: 0)
                }
                self.tableView.reloadData()
                if let nodeId = self.topicsController?.node?.id ?? self.composeController?.topic?.nodeId {
                    let section = self.sections.index { $0.nodes.contains { $0.id == nodeId } } ?? 0
                    let row = self.sections[section].nodes.index { $0.id == nodeId } ?? 0
                    let indexPath = IndexPath(row: row, section: section)
                    self.tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
                }
            } else {
                self.networkErrorView.isHidden = false
            }
            self.isRefreshing = false
        }
    }

    private func didSetRefreshing() {
        if isRefreshing {
            networkErrorView.isHidden = true
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
    }

    private var topicsController: TopicsController? {
        return ((presentingViewController as? UISplitViewController)?.viewControllers.first as? UINavigationController)?.viewControllers.first as? TopicsController
    }

    private var composeController: ComposeController? {
        return navigationController?.viewControllers.compactMap { $0 as? ComposeController }.last
    }
}

extension NodesController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].nodes.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].name
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UITableViewCell.description(), for: indexPath)
        let node = sections[indexPath.section].nodes[indexPath.row]
        cell.accessoryType = node.id == topicsController?.node?.id ?? composeController?.topic?.nodeId ? .checkmark : .none
        cell.textLabel?.text = node.name
        return cell
    }
}

extension NodesController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let node = sections[indexPath.section].nodes[indexPath.row]
        if topicsController != nil {
            topicsController?.node = node.id != nil ? node : nil
            dismiss(animated: true)
        } else {
            composeController?.setNode(node)
            navigationController?.popViewController(animated: true)
        }
    }
}
