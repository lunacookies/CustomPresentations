import UIKit

final class CustomSheetExampleViewController: UIViewController {
	override func loadView() {
		super.loadView()
		view.backgroundColor = .systemBackground

		var configuration = UIButton.Configuration.borderedProminent()
		configuration.buttonSize = .large
		let button = UIButton(
			configuration: configuration,
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

	func animationController(
		forPresented _: UIViewController,
		presenting _: UIViewController,
		source _: UIViewController,
	) -> (any UIViewControllerAnimatedTransitioning)? {
		CustomSheetAnimationController(operation: .present)
	}

	func animationController(forDismissed _: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
		CustomSheetAnimationController(operation: .dismiss)
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

private final class CustomSheetAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
	private let operation: Operation
	private let animator = UIViewPropertyAnimator(
		duration: 0,
		timingParameters: UISpringTimingParameters(mass: 1, stiffness: 200, damping: 25, initialVelocity: .zero),
	)

	init(operation: Operation) {
		self.operation = operation
	}

	func transitionDuration(using _: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
		animator.duration
	}

	func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
		let toViewController = transitionContext.viewController(forKey: .to)!
		let fromViewController = transitionContext.viewController(forKey: .from)!
		let presentedViewController = switch operation {
		case .present: toViewController
		case .dismiss: fromViewController
		}

		let presentedFrame = transitionContext.finalFrame(for: presentedViewController)
		var dismissedFrame = presentedFrame
		dismissedFrame.origin.y += dismissedFrame.size.height

		switch operation {
		case .present:
			transitionContext.containerView.addSubview(presentedViewController.view)
			presentedViewController.view.frame = dismissedFrame
			animator.addAnimations { presentedViewController.view.frame = presentedFrame }

		case .dismiss:
			animator.addAnimations { presentedViewController.view.frame = dismissedFrame }
		}

		animator.addCompletion { position in
			transitionContext.completeTransition(position == .end)
		}

		animator.startAnimation()
	}

	enum Operation {
		case present
		case dismiss
	}
}
