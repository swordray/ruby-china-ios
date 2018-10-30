//
//  TopicsCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit

class TopicsCell: UITableViewCell {

    public  var topic: Topic? { didSet { didSetTopic() } }
    private var userAvatarView: UIImageView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        detailTextLabel?.textColor = .lightGray

        let width = UIFontMetrics.default.scaledValue(for: 44)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: width), false, UIScreen.main.scale)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        imageView?.image = image

        textLabel?.numberOfLines = 3

        userAvatarView = UIImageView()
        userAvatarView.backgroundColor = UITableView(frame: .zero, style: .grouped).backgroundColor
        userAvatarView.clipsToBounds = true
        userAvatarView.layer.cornerRadius = width / 2
        imageView?.addSubview(userAvatarView)
        userAvatarView.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func didSetTopic() {
        detailTextLabel?.text = [
            topic?.nodeName != nil && (viewController as? TopicsController)?.node == nil ? "[\(topic?.nodeName ?? "")]" : nil,
            topic?.user?.login,
            topic?.repliedAt?.toRelative(),
            topic?.repliesCount ?? 0 > 0 ? "\(topic?.repliesCount ?? 0) ↵" : nil,
        ].compactMap { $0 }.joined(separator: " · ")
        textLabel?.text = topic?.title
        userAvatarView?.af_setImage(withURL: topic?.user?.avatarURL ?? .init(fileURLWithPath: ""))
    }
}
