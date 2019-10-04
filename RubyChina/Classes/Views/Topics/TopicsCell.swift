//
//  TopicsCell.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit

class TopicsCell: UITableViewCell {

    private var nodeButton: UIButton!
    private var repliedAtLabel: UILabel!
    private var repliesCountLabel: UILabel!
    private var titleLabel: UILabel!
    public  var topic: Topic? { didSet { didSetTopic() } }
    private var userAvatarView: UIImageView!
    private var userLoginLabel: UILabel!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.spacing = 15
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalTo(contentView.layoutMarginsGuide).priority(999) }

        userAvatarView = UIImageView()
        userAvatarView.backgroundColor = .secondarySystemBackground
        userAvatarView.clipsToBounds = true
        userAvatarView.layer.cornerRadius = 22
        userAvatarView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        userAvatarView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        stackView.addArrangedSubview(userAvatarView)
        userAvatarView.snp.makeConstraints { $0.size.equalTo(44) }

        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 8
        contentStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contentStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stackView.addArrangedSubview(contentStackView)

        titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .body)
        titleLabel.numberOfLines = 3
        contentStackView.addArrangedSubview(titleLabel)

        let detailStackView = UIStackView()
        detailStackView.spacing = 8
        contentStackView.addArrangedSubview(detailStackView)

        nodeButton = UIButton()
        nodeButton.backgroundColor = .quaternarySystemFill
        nodeButton.clipsToBounds = true
        nodeButton.contentEdgeInsets = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        nodeButton.isUserInteractionEnabled = false
        nodeButton.layer.cornerRadius = 3
        nodeButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        nodeButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        nodeButton.setTitleColor(.secondaryLabel, for: .normal)
        nodeButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        detailStackView.addArrangedSubview(nodeButton)

        userLoginLabel = UILabel()
        userLoginLabel.font = .preferredFont(forTextStyle: .subheadline)
        userLoginLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        userLoginLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        userLoginLabel.textColor = .secondaryLabel
        detailStackView.addArrangedSubview(userLoginLabel)

        repliedAtLabel = UILabel()
        repliedAtLabel.font = .preferredFont(forTextStyle: .subheadline)
        repliedAtLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        repliedAtLabel.textColor = .tertiaryLabel
        detailStackView.addArrangedSubview(repliedAtLabel)

        repliesCountLabel = UILabel()
        repliesCountLabel.font = .preferredFont(forTextStyle: .body)
        repliesCountLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        repliesCountLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        repliesCountLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(repliesCountLabel)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func didSetTopic() {
        userAvatarView.isHidden = topic?.user == nil
        userAvatarView.setImage(withURL: topic?.user?.avatarURL)
        titleLabel.text = topic?.title
        nodeButton.isHidden = (viewController as? TopicsController)?.node != nil
        nodeButton.setTitle(topic?.nodeName, for: .normal)
        userLoginLabel.isHidden = topic?.user == nil
        userLoginLabel.text = topic?.user?.login
        repliedAtLabel.text = topic?.repliedAt?.toRelative()
        repliesCountLabel.text = String(topic?.repliesCount ?? 0)

        if topic?.user != nil {
            let size = CGSize(width: 44, height: 1)
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            imageView?.image = image
        }
    }
}
