extension UIViewController {

    func alert(title: String?) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "好", style: .Default, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }

    func signIn() {
        let signInController = SignInController()
        signInController.viewController = self
        let navigationController = UINavigationController(rootViewController: signInController)
        navigationController.modalPresentationStyle = .FormSheet
        presentViewController(navigationController, animated: true, completion: nil)
    }
}
