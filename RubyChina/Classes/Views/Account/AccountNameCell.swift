//
//  AccountNameCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit

class AccountNameCell: UITableViewCell {

    public  var user: User? { didSet { didSetUser() } }
    private var userAvatarView: UIImageView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        detailTextLabel?.font = .preferredFont(forTextStyle: .subheadline)
        detailTextLabel?.text = " "
        detailTextLabel?.textColor = .secondaryLabel

        let size = CGSize(width: 44, height: 44)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        imageView?.image = image

        textLabel?.font = .preferredFont(forTextStyle: .title3)
        textLabel?.text = " "

        userAvatarView = UIImageView()
        userAvatarView.backgroundColor = .tertiarySystemGroupedBackground
        userAvatarView.clipsToBounds = true
        userAvatarView.layer.cornerRadius = 22
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
        userAvatarView.setImage(withURL: user?.avatarURL)
    }
}
