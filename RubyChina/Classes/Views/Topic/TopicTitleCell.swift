//
//  TopicTitleCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit

class TopicTitleCell: UITableViewCell {

    private var createdAtLabel: UILabel!
    private var hitsLabel: UILabel!
    private var titleLabel: UILabel!
    public  var topic: Topic? { didSet { didSetTopic() } }
    private var userAvatarView: UIImageView!
    private var userNameButton: UIButton!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalTo(contentView.layoutMarginsGuide) }

        titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 0
        stackView.addArrangedSubview(titleLabel)

        let detailStackView = UIStackView()
        detailStackView.spacing = 8
        stackView.addArrangedSubview(detailStackView)

        userAvatarView = UIImageView()
        userAvatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showUser)))
        userAvatarView.backgroundColor = .secondarySystemBackground
        userAvatarView.clipsToBounds = true
        userAvatarView.isUserInteractionEnabled = true
        userAvatarView.layer.cornerRadius = 22
        detailStackView.addArrangedSubview(userAvatarView)
        detailStackView.setCustomSpacing(15, after: userAvatarView)
        userAvatarView.snp.makeConstraints { $0.size.equalTo(44) }

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

        hitsLabel = UILabel()
        hitsLabel.font = .preferredFont(forTextStyle: .subheadline)
        hitsLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        hitsLabel.textColor = .tertiaryLabel
        detailStackView.addArrangedSubview(hitsLabel)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        userNameButton?.setTitleColor(tintColor, for: .normal)
        userNameButton?.setTitleColor(tintColor.withAlphaComponent(0.2), for: .highlighted)
    }

    private func didSetTopic() {
        titleLabel.text = topic?.title
        userAvatarView?.setImage(withURL: topic?.user?.avatarURL)
        userNameButton.setTitle(topic?.user?.login, for: .normal)
        createdAtLabel.text = topic?.createdAt?.toRelative()
        hitsLabel.text = topic?.hits ?? 0 > 0 ? "\(topic?.hits ?? 0)次阅读" : nil
    }

    @objc
    private func showUser() {
        let userController = UserController()
        userController.user = topic?.user
        viewController?.navigationController?.pushViewController(userController, animated: true)
    }
}
