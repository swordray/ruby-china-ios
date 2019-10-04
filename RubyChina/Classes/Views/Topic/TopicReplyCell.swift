//
//  TopicReplyCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit

class TopicReplyCell: TopicWebCell {

    private var createdAtLabel: UILabel!
    private var indexLabel: UILabel!
    public  var reply: Reply? { didSet { didSetReply() } }
    private var userAvatarView: UIImageView!
    private var userNameButton: UIButton!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let size = CGSize(width: 44, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        imageView?.image = image

        userAvatarView = UIImageView()
        userAvatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showUser)))
        userAvatarView.backgroundColor = .secondarySystemBackground
        userAvatarView.clipsToBounds = true
        userAvatarView.isUserInteractionEnabled = true
        userAvatarView.layer.cornerRadius = 22
        contentView.addSubview(userAvatarView)
        userAvatarView.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.leading.top.equalTo(contentView.layoutMarginsGuide)
        }

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.equalTo(userAvatarView.snp.trailing).offset(15)
            make.trailingMargin.topMargin.bottomMargin.equalToSuperview()
        }

        let detailStackView = UIStackView()
        detailStackView.spacing = 8
        stackView.addArrangedSubview(detailStackView)

        userNameButton = UIButton()
        userNameButton.addTarget(self, action: #selector(showUser), for: .touchUpInside)
        userNameButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .leastNormalMagnitude)
        userNameButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        userNameButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        detailStackView.addArrangedSubview(userNameButton)

        createdAtLabel = UILabel()
        createdAtLabel.font = .preferredFont(forTextStyle: .subheadline)
        createdAtLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        createdAtLabel.textColor = .secondaryLabel
        detailStackView.addArrangedSubview(createdAtLabel)

        indexLabel = UILabel()
        indexLabel.font = .preferredFont(forTextStyle: .subheadline)
        indexLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        indexLabel.textColor = .tertiaryLabel
        detailStackView.addArrangedSubview(indexLabel)

        stackView.addArrangedSubview(webView)
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        userNameButton?.setTitleColor(tintColor, for: .normal)
        userNameButton?.setTitleColor(tintColor.withAlphaComponent(0.2), for: .highlighted)
    }

    private func didSetReply() {
        userAvatarView.setImage(withURL: reply?.user?.avatarURL)
        userNameButton.setTitle(reply?.user?.login, for: .normal)
        createdAtLabel.text = reply?.createdAt?.toRelative()
        indexLabel.text = "#\((reply?.index ?? 0) + 1)"
        bodyHTML = reply?.bodyHTML
    }

    @objc
    private func showUser() {
        let userController = UserController()
        userController.user = reply?.user
        viewController?.navigationController?.pushViewController(userController, animated: true)
    }
}
