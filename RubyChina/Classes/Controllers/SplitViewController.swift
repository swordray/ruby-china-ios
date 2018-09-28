//
//  SplitViewController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 2018/3/23.
//  Copyright © 2018 Jianqiu Xiao. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController {

    private var defaultSecondaryViewController: UIViewController

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        defaultSecondaryViewController = UINavigationController()
        defaultSecondaryViewController.view.backgroundColor = .white

        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        viewControllers = [
            UINavigationController(rootViewController: TopicsController()),
            defaultSecondaryViewController,
        ]

        delegate = self
        preferredDisplayMode = .allVisible
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    internal func showDefault() {
        showDetailViewController(defaultSecondaryViewController, sender: nil)
    }
}

extension SplitViewController: UISplitViewControllerDelegate {

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return secondaryViewController == defaultSecondaryViewController
    }

    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        return (primaryViewController as? UINavigationController)?.viewControllers.last is UINavigationController ? nil : defaultSecondaryViewController
    }
}
