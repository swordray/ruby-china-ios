//
//  TopicTitleCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 5/28/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import AFNetworking
import MBProgressHUD
import MGSwipeTableCell
import SwiftyJSON
import UIKit

class TopicTitleCell: MGSwipeTableCell {

    var deleteButton = MGSwipeButton()
    var editButton = MGSwipeButton()
    var topic: JSON = [:]
    weak var topicController: TopicController?


    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        imageView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(user)))
        imageView?.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        imageView?.layer.cornerRadius = 22
        imageView?.layer.masksToBounds = true
        imageView?.isUserInteractionEnabled = true

        textLabel?.numberOfLines = 4

        detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        detailTextLabel?.textColor = .lightGray

        editButton.backgroundColor = UIColor(red: 199/255.0, green: 199/255.0, blue: 204/255.0, alpha: 1)
        editButton.buttonWidth = 66
        editButton.callback = { _ in
            let composeController = ComposeController()
            composeController.topic = self.topic
            self.topicController?.navigationController?.pushViewController(composeController, animated: true)
            return true
        }
        editButton.setTitle("编辑", for: .normal)

        deleteButton.backgroundColor = UIColor(red: 255/255.0, green: 59/255.0, blue: 48/255.0, alpha: 1)
        deleteButton.buttonWidth = 66
        deleteButton.callback = { _ in
            let alertController = UIAlertController(title: "确定删除吗？", message: nil, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "删除", style: .default) { _ in
                let progressHUD = MBProgressHUD.showAdded(to: self.topicController!.view, animated: false)
                let path = "/topics/\(self.topic["id"]).json"
                AFHTTPSessionManager(baseURL: Helper.baseURL).delete(path, parameters: nil, success: { task, responseObject in
                    progressHUD.hide(animated: false)
                    let navigationController = self.topicController?.navigationController
                    if navigationController != nil && navigationController!.viewControllers.count > 1 {
                        _ = navigationController?.popViewController(animated: true)
                    } else if navigationController?.navigationController != nil {
                        _ = navigationController?.navigationController?.popViewController(animated: true)
                    } else {
                        self.topicController?.splitViewController?.showDetailViewController(UIViewController(), sender: self)
                    }
                }) { task, error in
                    progressHUD.hide(animated: false)
                    if (task?.response as? HTTPURLResponse)?.statusCode == 401 { self.topicController?.signIn(); return }
                    self.topicController?.alert("网络错误")
                }
            })
            self.topicController?.navigationController?.present(alertController, animated: true, completion: nil)
            return false
        }
        deleteButton.setTitle("删除", for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView?.frame = CGRect(x: separatorInset.left, y: 11.5, width: 44, height: 44)
        if let url = URL(string: topic["user"]["avatar_url"].stringValue) { imageView?.setImageWith(url, placeholderImage: Helper.blankImage(imageView!.frame.size)) }

        textLabel?.frame = CGRect(x: separatorInset.left + 44 + 15, y: 11.5, width: frame.width - separatorInset.left * 2 - 44 - 15, height: 100)
        textLabel?.text = topic["title"].string
        textLabel?.frame.size.height = ceil(textLabel!.textRect(forBounds: textLabel!.frame, limitedToNumberOfLines: textLabel!.numberOfLines).height)

        detailTextLabel?.frame = CGRect(x: separatorInset.left + 44 + 15, y: 11.5 + textLabel!.frame.height + 5, width: bounds.width - separatorInset.left * 2 - 44 - 15, height: detailTextLabel!.frame.height)
        detailTextLabel?.text = "[\(topic["node_name"])] · \(topic["user"]["login"]) · \(Helper.timeAgoSinceNow(topic["created_at"].string))\(topic["hits"].int != nil ? " · \(topic["hits"]) 次阅读" : "")"

        rightButtons = ((topic["abilities"]["update"].boolValue ? [editButton] : [MGSwipeButton]()) + (topic["abilities"]["destroy"].boolValue ? [deleteButton] : [MGSwipeButton]())).reversed()

        frame.size.height = 11.5 + max(44, textLabel!.frame.height + 5 + detailTextLabel!.frame.height) + 11.5
    }

    func user() {
        let webViewController = WebViewController()
        webViewController.path = "\(Helper.baseURL.absoluteString)/\(topic["user"]["login"])"
        webViewController.title = topic["user"]["login"].string
        topicController?.navigationController?.pushViewController(webViewController, animated: true)
    }
}
