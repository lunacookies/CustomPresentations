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

	private var animationController: CustomPopoverAnimationController!

	func animationController(
		forPresented _: UIViewController,
		presenting _: UIViewController,
		source _: UIViewController,
	) -> (any UIViewControllerAnimatedTransitioning)? {
		animationController = CustomPopoverAnimationController(type: .presentation)
		return animationController
	}

	func animationController(forDismissed _: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
		animationController = CustomPopoverAnimationController(type: .dismissal)
		return animationController
	}

	func interactionControllerForPresentation(using _: any UIViewControllerAnimatedTransitioning)
		-> (any UIViewControllerInteractiveTransitioning)?
	{
		animationController
	}

	func interactionControllerForDismissal(using animator: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
		animationController
	}

	func presentationController(
		forPresented presented: UIViewController,
		presenting: UIViewController?,
		source _: UIViewController,
	) -> UIPresentationController? {
		let presentationController =
			CustomPopoverPresentationController(presentedViewController: presented, presenting: presenting)

		presentationController.didTapDimmingViewHandler = { [self] in
			animationController.cancelInteractiveTransition()
			presented.dismiss(animated: true)
		}

		return presentationController
	}
}

private final class CustomPopoverPresentationController: UIPresentationController {
	var didTapDimmingViewHandler: (() -> Void)?

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
		let touchForwardingView = TouchForwardingView()
		touchForwardingView.passthroughViews = [presentingViewController.view]
		containerView!.embed(touchForwardingView)
		containerView!.sendSubviewToBack(touchForwardingView)

		dimmingView = UIView()
		dimmingView.backgroundColor = .black
		dimmingView.alpha = 0
		dimmingView.addSubview(presentedView!)
		containerView!.embed(dimmingView)

		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapDimmingView(_:)))
		dimmingView.addGestureRecognizer(tapGestureRecognizer)

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

	@objc
	private func didTapDimmingView(_: UITapGestureRecognizer) {
		didTapDimmingViewHandler?()
		dimmingView.isUserInteractionEnabled = false
	}

	private final class TouchForwardingView: UIView {
		var passthroughViews = [UIView]()

		override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
			let hitView = super.hitTest(point, with: event)
			guard hitView == self else { return hitView }
			for passthroughView in passthroughViews {
				if let passthroughHitView = passthroughView.hitTest(convert(point, to: passthroughView), with: event) {
					return passthroughHitView
				}
			}
			return self
		}
	}
}

private final class CustomPopoverAnimationController: NSObject,
	UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning
{
	private let type: PresentationType
	private var animator: UIViewPropertyAnimator?
	private var transitionContext: (any UIViewControllerContextTransitioning)?

	init(type: PresentationType) {
		self.type = type
	}

	func transitionDuration(using _: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
		type == .presentation ? 0.4 : 0.3
	}

	func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
		interruptibleAnimator(using: transitionContext).startAnimation()
	}

	func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {
		animateTransition(using: transitionContext)
	}

	func interruptibleAnimator(using transitionContext: any UIViewControllerContextTransitioning)
		-> any UIViewImplicitlyAnimating
	{
		if let animator { return animator }
		self.transitionContext = transitionContext

		let duration = transitionDuration(using: transitionContext)
		let bounce: CGFloat = type == .presentation ? 0.2 : 0
		let timingParameters = UISpringTimingParameters(duration: duration, bounce: bounce)
		let animator = UIViewPropertyAnimator(duration: 0, timingParameters: timingParameters)
		self.animator = animator

		guard
			let fromViewController = transitionContext.viewController(forKey: .from),
			let toViewController = transitionContext.viewController(forKey: .to),
			let fromView = fromViewController.view,
			let toView = toViewController.view
		else {
			transitionContext.completeTransition(false)
			return animator
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

		animator.addAnimations { [self] in
			presentedView.transform = type == .presentation ? presentedTransform : dismissedTransform
		}
		animator.addCompletion { position in
			transitionContext.completeTransition(position == .end)
		}

		return animator
	}

	func cancelInteractiveTransition() {
		transitionContext!.cancelInteractiveTransition()
		animator!.isReversed = true
	}

	enum PresentationType {
		case presentation
		case dismissal
	}
}
