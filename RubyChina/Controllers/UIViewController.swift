extension UIViewController {

    func alert(_ title: String?) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "好", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    func signIn() {
        let signInController = SignInController()
        signInController.viewController = self
        let navigationController = UINavigationController(rootViewController: signInController)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true, completion: nil)
    }
}
