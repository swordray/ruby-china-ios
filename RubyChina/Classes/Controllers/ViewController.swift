//
//  ViewController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import JGProgressHUD

class ViewController: GAITrackedViewController {

    private var progressHUD: JGProgressHUD?

    init() {
        super.init(nibName: nil, bundle: nil)

        screenName = String(describing: type(of: self))
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        userActivity?.becomeCurrent()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        userActivity?.invalidate()
    }

    internal var baseURL: URL {
        return URL(string: Bundle.main.infoDictionary?["BaseURLString"] as? String ?? "") ?? .init(fileURLWithPath: "")
    }

    @objc
    internal func dismiss(_ sender: Any? = nil) {
        view.endEditing(true)
        dismiss(animated: true)
    }

    internal func hideHUD() {
        progressHUD?.dismiss(animated: false)
    }

    internal func networkError() {
        let alertController = UIAlertController(title: "网络错误", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "好", style: .default))
        present(alertController, animated: true)
    }

    internal func showHUD() {
        var ancestor: UIViewController = self
        while let parent = ancestor.parent { ancestor = parent }
        progressHUD = progressHUD ?? JGProgressHUD(style: .extraLight)
        progressHUD?.show(in: ancestor.view, animated: false)
    }

    @objc
    internal func showSignIn(_ sender: Any? = nil) {
        let navigationController = UINavigationController(rootViewController: SignInController())
        navigationController.modalPresentationStyle = sender is UIBarButtonItem ? .popover : .formSheet
        navigationController.popoverPresentationController?.backgroundColor = UIColor(displayP3Red: 248 / 255, green: 248 / 255, blue: 248 / 255, alpha: 1)
        navigationController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
        present(navigationController, animated: true)
    }
}
