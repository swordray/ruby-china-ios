//
//  SplitViewController.swift
//  RubyChina
//
//  Created by Jianqiu Xiao on 6/4/15.
//  Copyright (c) 2015 Jianqiu Xiao. All rights reserved.
//

import UIKit

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {

    override func loadView() {
        addChildViewController(UINavigationController(rootViewController: TopicsController()))
        addChildViewController(UIViewController())
        super.loadView()
    }

    override func viewDidLoad() {
        delegate = self
        preferredDisplayMode = .allVisible
        view.backgroundColor = Helper.backgroundColor
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return (secondaryViewController as? UINavigationController) == nil
    }

    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if (primaryViewController as? UINavigationController)?.viewControllers.last as? UINavigationController == nil { return UIViewController() }
        return nil
    }

    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewControllerDisplayMode) {
        (svc.viewControllers.last as? UINavigationController)?.viewControllers.last?.traitCollectionDidChange(nil)
    }
}
