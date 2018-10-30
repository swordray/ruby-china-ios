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
    private var previewings: [UIViewControllerPreviewing]?
    private var titleLabel: UILabel!
    public  var topic: Topic? { didSet { didSetTopic() } }
    private var userAvatarView: UIImageView!
    private var userNameButton: UIButton!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = UIFont.preferredFont(forTextStyle: .body).lineHeight * 0.5
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.margins.equalToSuperview() }

        titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 0
        stackView.addArrangedSubview(titleLabel)

        let detailStackView = UIStackView()
        detailStackView.spacing = 15
        stackView.addArrangedSubview(detailStackView)

        let width = UIFontMetrics.default.scaledValue(for: 44)

        userAvatarView = UIImageView()
        userAvatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showUser)))
        userAvatarView.backgroundColor = UITableView(frame: .zero, style: .grouped).backgroundColor
        userAvatarView.clipsToBounds = true
        userAvatarView.isUserInteractionEnabled = true
        userAvatarView.layer.cornerRadius = width / 2
        userAvatarView.snp.makeConstraints { $0.size.equalTo(width) }
        detailStackView.addArrangedSubview(userAvatarView)

        userNameButton = UIButton()
        userNameButton.addTarget(self, action: #selector(showUser), for: .touchUpInside)
        userNameButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .leastNormalMagnitude)
        userNameButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        userNameButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        detailStackView.addArrangedSubview(userNameButton)

        createdAtLabel = UILabel()
        createdAtLabel.font = .preferredFont(forTextStyle: .subheadline)
        createdAtLabel.numberOfLines = 0
        createdAtLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        createdAtLabel.textAlignment = .right
        createdAtLabel.textColor = .lightGray
        detailStackView.addArrangedSubview(createdAtLabel)
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
        userAvatarView?.af_setImage(withURL: topic?.user?.avatarURL ?? .init(fileURLWithPath: ""))
        userNameButton.setTitle(topic?.user?.login, for: .normal)
        createdAtLabel.text = [
            topic?.createdAt?.toRelative(),
            topic?.hits ?? 0 > 0 ? "\(topic?.hits ?? 0)次阅读" : nil,
        ].compactMap { $0 }.joined(separator: " · ")
    }

    private func userController() -> WebViewController {
        let login = topic?.user?.login ?? ""
        let webViewController = WebViewController()
        webViewController.title = login
        webViewController.url = viewController?.baseURL.appendingPathComponent(login)
        return webViewController
    }

    @objc
    private func showUser() {
        viewController?.show(userController(), sender: nil)
    }

    internal func willDisplay() {
        if traitCollection.forceTouchCapability == .unavailable { return }
        previewings = previewings ?? [userAvatarView, userNameButton].compactMap { viewController?.registerForPreviewing(with: self, sourceView: $0) }
    }

    internal func didEndDisplaying() {
        previewings?.forEach { viewController?.unregisterForPreviewing(withContext: $0) }
        previewings = nil
    }
}

extension TopicTitleCell: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        return userController()
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewController?.show(viewControllerToCommit, sender: nil)
    }
}
