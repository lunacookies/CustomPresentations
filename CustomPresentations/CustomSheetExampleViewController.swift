import UIKit

final class CustomSheetExampleViewController: UIViewController {
	override func loadView() {
		super.loadView()
		view.backgroundColor = .systemBackground

		let button = UIButton(
			configuration: .borderedTinted(),
			primaryAction: UIAction(title: "Present") { [weak self] _ in
				guard let self else { return }
				didTapButton()
			},
		)

		button.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(button)
		NSLayoutConstraint.activate([
			button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
		])
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Custom Sheet"
	}

	private func didTapButton() {
		let presentedViewController = UINavigationController(rootViewController: ContentViewController())
		presentedViewController.modalPresentationStyle = .custom
		presentedViewController.transitioningDelegate = self
		present(presentedViewController, animated: true)
	}
}

extension CustomSheetExampleViewController: UIViewControllerTransitioningDelegate {
	func presentationController(
		forPresented presented: UIViewController,
		presenting: UIViewController?,
		source _: UIViewController,
	) -> UIPresentationController? {
		CustomSheetPresentationController(presentedViewController: presented, presenting: presenting)
	}
}

private final class CustomSheetPresentationController: UIPresentationController {
	private var dimmingView: UIView!

	override var frameOfPresentedViewInContainerView: CGRect {
		let containerSize = containerView!.bounds.size
		let size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerSize)
		var rect = CGRect(origin: .zero, size: size)
		rect.origin.y = containerSize.height - size.height
		return rect
	}

	override func size(
		forChildContentContainer _: any UIContentContainer,
		withParentContainerSize parentSize: CGSize,
	) -> CGSize {
		var size = parentSize
		size.height *= 0.4
		return size
	}

	override func presentationTransitionWillBegin() {
		let containerView = containerView!

		dimmingView = UIView()
		dimmingView.backgroundColor = .black
		dimmingView.alpha = 0

		dimmingView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(dimmingView)
		NSLayoutConstraint.activate([
			dimmingView.topAnchor.constraint(equalTo: containerView.topAnchor),
			dimmingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
			dimmingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
			dimmingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
		])

		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapDimmingView(_:)))
		dimmingView.addGestureRecognizer(tapGestureRecognizer)

		presentedViewController.transitionCoordinator?.animate { [self] _ in
			dimmingView.alpha = 0.2
		}
	}

	override func dismissalTransitionWillBegin() {
		presentedViewController.transitionCoordinator?.animate { [self] _ in
			dimmingView.alpha = 0
		}
	}

	@objc
	private func didTapDimmingView(_: UITapGestureRecognizer) {
		presentedViewController.dismiss(animated: true)
	}
}
