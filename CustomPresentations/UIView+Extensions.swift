import UIKit

extension UIView {
	func embed(_ view: UIView) {
		view.translatesAutoresizingMaskIntoConstraints = false
		addSubview(view)
		NSLayoutConstraint.activate([
			view.topAnchor.constraint(equalTo: topAnchor),
			view.leadingAnchor.constraint(equalTo: leadingAnchor),
			view.trailingAnchor.constraint(equalTo: trailingAnchor),
			view.bottomAnchor.constraint(equalTo: bottomAnchor),
		])
	}

	func embed(centered view: UIView) {
		view.translatesAutoresizingMaskIntoConstraints = false
		addSubview(view)
		NSLayoutConstraint.activate([
			view.centerXAnchor.constraint(equalTo: centerXAnchor),
			view.centerYAnchor.constraint(equalTo: centerYAnchor),
			view.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
			view.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
			view.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),
			view.bottomAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.bottomAnchor),
		])
	}
}
