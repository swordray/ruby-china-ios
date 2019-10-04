//
//  UserHeaderView.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 6/16/19.
//  Copyright © 2019 Jianqiu Xiao. All rights reserved.
//

import UIKit

class UserHeaderView: UITableViewHeaderFooterView {

    private var avatarView: UIImageView!
    private var loginLabel: UILabel!
    public  var user: User? { didSet { didSetUser() } }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 12
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leadingMargin.trailingMargin.equalToSuperview()
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-20).priority(999)
        }

        avatarView = UIImageView()
        avatarView.backgroundColor = .secondarySystemGroupedBackground
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 44
        avatarView.snp.makeConstraints { $0.size.equalTo(88) }
        stackView.addArrangedSubview(avatarView)

        loginLabel = UILabel()
        loginLabel.font = .preferredFont(forTextStyle: .title1)
        stackView.addArrangedSubview(loginLabel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func didSetUser() {
        avatarView.setImage(withURL: user?.largeAvatarURL)
        loginLabel.text = user?.login
    }
}
