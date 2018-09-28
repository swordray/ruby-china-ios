//
//  UserNameCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit

class UserNameCell: UITableViewCell {

    public  var user: User? { didSet { didSetUser() } }
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

        textLabel?.font = .preferredFont(forTextStyle: .title2)

        userAvatarView = UIImageView()
        userAvatarView.backgroundColor = UITableView(frame: .zero, style: .grouped).backgroundColor
        userAvatarView.clipsToBounds = true
        userAvatarView.layer.cornerRadius = width / 2
        contentView.addSubview(userAvatarView)
        userAvatarView.snp.makeConstraints { $0.edges.equalTo(imageView ?? .init()) }
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func didSetUser() {
        detailTextLabel?.text = user?.name ?? user?.login
        textLabel?.text = user?.login
        userAvatarView.af_setImage(withURL: user?.avatarURL ?? .init(fileURLWithPath: ""))
    }
}
