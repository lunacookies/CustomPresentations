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

	func animationController(
		forPresented _: UIViewController,
		presenting _: UIViewController,
		source _: UIViewController,
	) -> (any UIViewControllerAnimatedTransitioning)? {
		CustomPopoverAnimationController(type: .presentation)
	}

	func animationController(forDismissed _: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
		CustomPopoverAnimationController(type: .dismissal)
	}

	func presentationController(
		forPresented presented: UIViewController,
		presenting: UIViewController?,
		source _: UIViewController,
	) -> UIPresentationController? {
		CustomPopoverPresentationController(presentedViewController: presented, presenting: presenting)
	}
}

private final class CustomPopoverPresentationController: UIPresentationController {
	private var dimmingView: UIView!

	override var frameOfPresentedViewInContainerView: CGRect {
		guard let containerView else { return .zero }
		let size = CGSize(width: 300, height: 300)
		var origin = CGPoint(x: containerView.bounds.midX, y: containerView.bounds.midY)
		origin.x -= size.width / 2
		origin.y += 50
		return CGRect(origin: origin, size: size)
	}

	override func presentationTransitionWillBegin() {
		dimmingView = UIView()
		dimmingView.backgroundColor = .black
		dimmingView.alpha = 0
		dimmingView.addSubview(presentedView!)
		containerView!.addSubview(dimmingView)
		dimmingView.frame = containerView!.bounds

		if let transitionCoordinator = presentedViewController.transitionCoordinator {
			transitionCoordinator.animate { [dimmingView] _ in
				dimmingView!.alpha = 0.1
			}
		}
	}

	override func presentationTransitionDidEnd(_ completed: Bool) {
		guard !completed else { return }
		dimmingView.removeFromSuperview()
	}

	override func dismissalTransitionWillBegin() {
		if let transitionCoordinator = presentedViewController.transitionCoordinator {
			transitionCoordinator.animate { [dimmingView] _ in
				dimmingView!.alpha = 0
			}
		}
	}

	override func dismissalTransitionDidEnd(_ completed: Bool) {
		guard completed else { return }
		dimmingView.removeFromSuperview()
	}
}

private final class CustomPopoverAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
	private let type: PresentationType

	init(type: PresentationType) {
		self.type = type
	}

	func transitionDuration(using _: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
		type == .presentation ? 0.4 : 0.2
	}

	func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
		guard
			let fromViewController = transitionContext.viewController(forKey: .from),
			let toViewController = transitionContext.viewController(forKey: .to),
			let fromView = fromViewController.view,
			let toView = toViewController.view
		else {
			transitionContext.completeTransition(false)
			return
		}

		let (presentedViewController, presentedView) = switch type {
		case .presentation: (toViewController, toView)
		case .dismissal: (fromViewController, fromView)
		}

		if type == .presentation {
			let containerView = transitionContext.containerView
			containerView.addSubview(presentedView)
		}

		let finalFrame = transitionContext.finalFrame(for: presentedViewController)
		presentedView.frame = finalFrame

		let presentedTransform = CGAffineTransform.identity
		let dismissedTransform = CGAffineTransform(translationX: 0, y: -0.5 * finalFrame.height)
			.scaledBy(x: 0.001, y: 0.001)

		presentedView.transform = type == .presentation ? dismissedTransform : presentedTransform

		let duration = transitionDuration(using: transitionContext)
		let bounce: CGFloat = type == .presentation ? 0.2 : 0
		let timingParameters = UISpringTimingParameters(duration: duration, bounce: bounce)
		let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)

		animator.addAnimations { [self] in
			presentedView.transform = type == .presentation ? presentedTransform : dismissedTransform
		}
		animator.addCompletion { position in
			transitionContext.completeTransition(position == .end)
		}
		animator.startAnimation()
	}

	enum PresentationType {
		case presentation
		case dismissal
	}
}
