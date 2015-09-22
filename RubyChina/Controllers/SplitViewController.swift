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
        preferredDisplayMode = .AllVisible
        view.backgroundColor = Helper.backgroundColor
    }

    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return (secondaryViewController as? UINavigationController) == nil
    }

    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController primaryViewController: UIViewController) -> UIViewController? {
        if (primaryViewController as? UINavigationController)?.viewControllers.last as? UINavigationController == nil { return UIViewController() }
        return nil
    }

    func splitViewController(svc: UISplitViewController, willChangeToDisplayMode displayMode: UISplitViewControllerDisplayMode) {
        (svc.viewControllers.last as? UINavigationController)?.viewControllers.last?.traitCollectionDidChange(nil)
    }
}
