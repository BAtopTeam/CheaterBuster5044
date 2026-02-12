import Foundation
import SwiftUI

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {

    override open func viewDidLoad() {

        super.viewDidLoad()

        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        return viewControllers.count > 1
    }
}

public func hideKeyboard() {
    UIApplication.shared.endEditing()
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
