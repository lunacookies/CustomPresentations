import UIKit

final class CustomSheetExampleViewController: UIViewController {
	private var customSheetTransitioningDelegate = CustomSheetTransitioningDelegate()

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

		view.embed(centered: button)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Custom Sheet"
	}

	private func didTapButton() {
		let presentedViewController = UINavigationController(rootViewController: ContentViewController())
		presentedViewController.modalPresentationStyle = .custom
		presentedViewController.transitioningDelegate = customSheetTransitioningDelegate
		present(presentedViewController, animated: true)
	}
}

private final class CustomSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
	private var presentationController: CustomSheetPresentationController?

	func presentationController(
		forPresented presented: UIViewController,
		presenting: UIViewController?,
		source _: UIViewController,
	) -> UIPresentationController? {
		presentationController = CustomSheetPresentationController(
			presentedViewController: presented,
			presenting: presenting,
		)
		return presentationController!
	}

	func animationController(
		forPresented _: UIViewController,
		presenting _: UIViewController,
		source _: UIViewController,
	) -> (any UIViewControllerAnimatedTransitioning)? {
		presentationController!.operation = .present
		return presentationController!
	}

	func animationController(forDismissed _: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
		presentationController!.operation = .dismiss
		return presentationController!
	}

	func interactionControllerForPresentation(using _: any UIViewControllerAnimatedTransitioning)
		-> (any UIViewControllerInteractiveTransitioning)?
	{
		presentationController!.operation = .present
		return presentationController!
	}

	func interactionControllerForDismissal(using _: any UIViewControllerAnimatedTransitioning)
		-> (any UIViewControllerInteractiveTransitioning)?
	{
		presentationController!.operation = .dismiss
		return presentationController!
	}
}

private final class CustomSheetPresentationController: UIPresentationController {
	var operation: Operation? {
		didSet { configuredAnimator = false }
	}

	private var sheetView: ContentVisualEffectView!
	private var blurView: UIVisualEffectView!
	private var dimmingView: UIView!
	private let animator = UIViewPropertyAnimator(
		duration: 0,
		timingParameters: UISpringTimingParameters(duration: 0.5, bounce: 0.3),
	)
	private var configuredAnimator = false
	private var transitionContext: (any UIViewControllerContextTransitioning)!

	override func presentationTransitionWillBegin() {
		let containerView = containerView!
		let presentedView = presentedView!

		blurView = UIVisualEffectView()
		containerView.embed(blurView)

		dimmingView = UIView()
		dimmingView.backgroundColor = UIColor(white: 0.3, alpha: 1)
		dimmingView.alpha = 0
		containerView.embed(dimmingView)
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapDimmingView(_:)))
		dimmingView.addGestureRecognizer(tapGestureRecognizer)

		let displayCornerRadius = containerView.window!.screen.displayCornerRadius
		let presentedViewPadding: CGFloat = 20
		presentedView.layer.cornerRadius = displayCornerRadius - presentedViewPadding

		sheetView = ContentVisualEffectView()
		sheetView.layer.shadowOffset = CGSize(width: 0, height: -5)
		sheetView.layer.shadowColor = UIColor.black.cgColor
		sheetView.contentView.embed(presentedView)

		sheetView.translatesAutoresizingMaskIntoConstraints = false
		containerView.addSubview(sheetView)
		containerView.keyboardLayoutGuide.usesBottomSafeArea = false

		NSLayoutConstraint.activate([
			sheetView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: presentedViewPadding),
			sheetView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -presentedViewPadding),
			sheetView.bottomAnchor.constraint(
				equalTo: containerView.keyboardLayoutGuide.topAnchor,
				constant: -presentedViewPadding,
			),
			sheetView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 1 / 3),
		])

		configure(for: .dismiss)
	}

	override func presentationTransitionDidEnd(_ completed: Bool) {
		if !completed {
			presentingViewController.view.layer.cornerRadius = 0
		}
	}

	override func dismissalTransitionDidEnd(_: Bool) {
		presentingViewController.view.layer.cornerRadius = 0
	}

	@objc
	private func didTapDimmingView(_: UITapGestureRecognizer) {
		guard animator.isRunning else {
			presentedViewController.dismiss(animated: true)
			return
		}

		transitionContext.cancelInteractiveTransition()
		operation = .dismiss
		animate()
	}

	private func animate() {
		animator.addAnimations { [self] in configure(for: operation!) }
		animator.addCompletion { [self] _ in
			transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
			if operation == .dismiss {
				presentedViewController.dismiss(animated: true)
			}
		}
	}

	private func configure(for operation: Operation) {
		let presentedView = presentedView!
		let presentingView = presentingViewController.view!
		let displayCornerRadius = presentingView.window!.screen.displayCornerRadius

		switch operation {
		case .present:
			let presentingViewScale = 0.95
			let gapAbovePresentingView = presentingView.frame.height * (1 - presentingViewScale) / 2
			let gapBesidePresentingView = presentingView.frame.width * (1 - presentingViewScale) / 3

			presentingView.transform =
				CGAffineTransform(scaleX: presentingViewScale, y: presentingViewScale)
					.translatedBy(x: 0, y: gapAbovePresentingView)
			presentingView.layer.cornerRadius = displayCornerRadius - gapBesidePresentingView
			presentedView.transform = .identity
			blurView.effect = UIBlurEffect.effect(withBlurRadius: 2)
			dimmingView.alpha = 0.5
			sheetView.effect = nil
			sheetView.alpha = 1
			sheetView.layer.shadowOpacity = 0.5
			sheetView.layer.shadowRadius = 40

		case .dismiss:
			containerView?.layoutIfNeeded()
			let dismissedTransform = CGAffineTransform(translationX: 0, y: presentedView.frame.height)
				.scaledBy(x: 0.1, y: 1)

			presentedView.transform = dismissedTransform
			presentingView.transform = .identity
			presentingView.layer.cornerRadius = displayCornerRadius
			blurView.effect = nil
			dimmingView.alpha = 0
			sheetView.effect = UIBlurEffect.effect(withBlurRadius: 40)
			sheetView.alpha = 0.5
			sheetView.layer.shadowOpacity = 0
			sheetView.layer.shadowRadius = 0
		}
	}

	enum Operation {
		case present
		case dismiss
	}
}

extension CustomSheetPresentationController: UIViewControllerAnimatedTransitioning {
	func transitionDuration(using _: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
		animator.duration
	}

	func animateTransition(using _: any UIViewControllerContextTransitioning) {
		fatalError()
	}
}

extension CustomSheetPresentationController: UIViewControllerInteractiveTransitioning {
	func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {
		self.transitionContext = transitionContext
		animate()
		animator.startAnimation()
	}
}

private final class ContentVisualEffectView: UIVisualEffectView {
	override var effect: UIVisualEffect? {
		get {
			guard responds(to: NSSelectorFromString("contentEffects")) else { return nil }
			let contentEffects = value(forKey: "contentEffects") as? [UIVisualEffect]
			return contentEffects?.first
		}
		set {
			guard responds(to: NSSelectorFromString("setContentEffects:")) else { return }
			var contentEffects = [UIVisualEffect]()
			if let effect = newValue {
				contentEffects = [effect]
			}
			setValue(contentEffects, forKey: "contentEffects")
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		subviews[0].layer.setValue(false, forKeyPath: "filters.gaussianBlur.inputNormalizeEdges")
	}
}

private extension UIBlurEffect {
	static func effect(withBlurRadius blurRadius: CGFloat) -> UIBlurEffect? {
		let selector = NSSelectorFromString("effectWithBlurRadius:")
		guard let implementation = UIBlurEffect.method(for: selector) else { return nil }
		let methodType = (@convention(c) (AnyClass, Selector, CGFloat) -> UIBlurEffect?).self
		let method = unsafeBitCast(implementation, to: methodType)
		return method(UIBlurEffect.self, selector, blurRadius)
	}
}

private extension UIScreen {
	var displayCornerRadius: CGFloat {
		value(forKey: "_displayCornerRadius") as? CGFloat ?? 0
	}
}
