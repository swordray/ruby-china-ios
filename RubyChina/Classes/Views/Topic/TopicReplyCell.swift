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
    private var previewings: [UIViewControllerPreviewing]?
    public  var reply: Reply? { didSet { didSetReply() } }
    private var userAvatarView: UIImageView!
    private var userNameButton: UIButton!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let width = UIFontMetrics.default.scaledValue(for: 44)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: width), false, UIScreen.main.scale)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        imageView?.image = image

        userAvatarView = UIImageView()
        userAvatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showUser)))
        userAvatarView.backgroundColor = UITableView(frame: .zero, style: .grouped).backgroundColor
        userAvatarView.clipsToBounds = true
        userAvatarView.isUserInteractionEnabled = true
        userAvatarView.layer.cornerRadius = width / 2
        contentView.addSubview(userAvatarView)
        userAvatarView.snp.makeConstraints { make in
            make.size.equalTo(width)
            make.leading.equalTo(contentView.layoutMarginsGuide)
            make.top.equalTo(UIFontMetrics.default.scaledValue(for: 13.5))
        }

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = UIFont.preferredFont(forTextStyle: .body).lineHeight * 0.5
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.equalTo(userAvatarView.snp.trailing).offset(15)
            make.trailing.equalTo(contentView.layoutMarginsGuide)
            make.top.equalTo(UIFontMetrics.default.scaledValue(for: 13.5))
            make.bottom.equalTo(UIFontMetrics.default.scaledValue(for: -13.5))
        }

        let detailStackView = UIStackView()
        detailStackView.spacing = 15
        stackView.addArrangedSubview(detailStackView)

        userNameButton = UIButton()
        userNameButton.addTarget(self, action: #selector(showUser), for: .touchUpInside)
        userNameButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .leastNormalMagnitude)
        userNameButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        userNameButton.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        detailStackView.addArrangedSubview(userNameButton)

        createdAtLabel = UILabel()
        createdAtLabel.font = .preferredFont(forTextStyle: .footnote)
        createdAtLabel.numberOfLines = 0
        createdAtLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        createdAtLabel.textAlignment = .right
        createdAtLabel.textColor = .lightGray
        detailStackView.addArrangedSubview(createdAtLabel)

        stackView.addArrangedSubview(webView)
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        userNameButton?.setTitleColor(tintColor, for: .normal)
        userNameButton?.setTitleColor(tintColor.withAlphaComponent(0.2), for: .highlighted)
    }

    private func didSetReply() {
        userAvatarView.af_setImage(withURL: reply?.user?.avatarURL ?? .init(fileURLWithPath: ""))
        userNameButton.setTitle(reply?.user?.login, for: .normal)
        createdAtLabel.text = [
            reply?.createdAt?.toRelative(),
            "#\((reply?.index ?? 0) + 1)",
        ].compactMap { $0 }.joined(separator: " · ")
        bodyHTML = reply?.bodyHTML
    }

    private func userController() -> WebViewController {
        let login = reply?.user?.login ?? ""
        let webViewController = WebViewController()
        webViewController.title = login
        webViewController.url = viewController?.baseURL.appendingPathComponent(login)
        return webViewController
    }

    @objc
    private func showUser() {
        viewController?.show(userController(), sender: nil)
    }

    internal func registerPreviewing() {
        if traitCollection.forceTouchCapability == .unavailable { return }
        previewings = previewings ?? [userAvatarView, userNameButton].compactMap { viewController?.registerForPreviewing(with: self, sourceView: $0) }
    }

    internal func unregisterPreviewing() {
        previewings?.forEach { viewController?.unregisterForPreviewing(withContext: $0) }
        previewings = nil
    }
}

extension TopicReplyCell: UIViewControllerPreviewingDelegate {

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        return userController()
    }

    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        viewController?.show(viewControllerToCommit, sender: nil)
    }
}
