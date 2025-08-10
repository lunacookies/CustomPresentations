import UIKit

final class CustomPopoverExampleViewController: UIViewController {
	override func loadView() {
		super.loadView()
		view.backgroundColor = .systemBackground

		let button = UIButton(
			configuration: .borderedProminent(),
			primaryAction: UIAction(title: "Present") { [weak self] _ in
				guard let self else { return }
				let presentedViewController = UINavigationController(rootViewController: ContentViewController())
				presentedViewController.modalPresentationStyle = .custom
				presentedViewController.transitioningDelegate = CustomPopoverTransitioningDelegate.shared
				present(presentedViewController, animated: true)
			},
		)

		view.embed(centered: button)
	}
}

private final class CustomPopoverTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
	static let shared = CustomPopoverTransitioningDelegate()

	func presentationController(
		forPresented presented: UIViewController,
		presenting: UIViewController?,
		source _: UIViewController,
	) -> UIPresentationController? {
		CustomPopoverPresentationController(presentedViewController: presented, presenting: presenting)
	}
}

private final class CustomPopoverPresentationController: UIPresentationController {
	override var frameOfPresentedViewInContainerView: CGRect {
		guard let containerView else { return .zero }
		let size = CGSize(width: 300, height: 300)
		var origin = CGPoint(x: containerView.bounds.midX, y: containerView.bounds.midY)
		origin.x -= size.width / 2
		origin.y += 50
		return CGRect(origin: origin, size: size)
	}
}
