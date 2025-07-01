import UIKit

final class ContentViewController: UICollectionViewController {
	private let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Item> { cell, _, item in
		switch item {
		case .text:
			var contentConfiguration = UIListContentConfiguration.cell()
			contentConfiguration.text = "Some Text"
			cell.contentConfiguration = contentConfiguration

		case .textField:
			var contentConfiguration = TextFieldContentConfiguration()
			contentConfiguration.labelText = "Some Text"
			contentConfiguration.placeholderText = "John Appleseed"
			cell.contentConfiguration = contentConfiguration
		}
	}

	init() {
		super.init(collectionViewLayout: UICollectionViewCompositionalLayout { _, layoutEnvironment in
			let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
			return NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
		})
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Presentation Content"
		navigationItem.rightBarButtonItem = UIBarButtonItem(
			systemItem: .close,
			primaryAction: UIAction { [weak self] _ in
				guard let self else { return }
				dismiss(animated: true)
			},
		)
		collectionView.keyboardDismissMode = .onDrag
	}

	override func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
		Item.allCases.count
	}

	override func collectionView(_: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let item = Item(rawValue: indexPath.item)!
		return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
	}

	override func collectionView(_: UICollectionView, shouldSelectItemAt _: IndexPath) -> Bool {
		false
	}

	private enum Item: Int, CaseIterable {
		case text
		case textField
	}
}

private struct TextFieldContentConfiguration: UIContentConfiguration {
	var labelText = "" {
		didSet { listContentConfiguration.text = labelText }
	}

	var valueText = ""
	var placeholderText = ""

	fileprivate var listContentConfiguration = UIListContentConfiguration.valueCell()

	func makeContentView() -> any UIView & UIContentView {
		TextFieldContentView(configuration: self)
	}

	func updated(for state: any UIConfigurationState) -> TextFieldContentConfiguration {
		var updated = self
		updated.listContentConfiguration = listContentConfiguration.updated(for: state)
		return updated
	}
}

private final class TextFieldContentView: UIView, UIContentView {
	var configuration: any UIContentConfiguration {
		didSet {
			guard let configuration = configuration as? TextFieldContentConfiguration else { return }

			let listContentConfiguration = configuration.listContentConfiguration
			listContentView.configuration = listContentConfiguration
			textField.text = configuration.valueText
			textField.placeholder = configuration.placeholderText

			let textLayoutGuide = listContentView.textLayoutGuide!
			NSLayoutConstraint.activate([
				textField.centerYAnchor.constraint(equalTo: textLayoutGuide.centerYAnchor),
				textField.leadingAnchor.constraint(
					equalTo: textLayoutGuide.trailingAnchor,
					constant: listContentConfiguration.textToSecondaryTextHorizontalPadding,
				),
				textField.trailingAnchor.constraint(equalTo: listContentView.layoutMarginsGuide.trailingAnchor),
			])
		}
	}

	let listContentView: UIListContentView
	let textField: UITextField

	init(configuration: any UIContentConfiguration) {
		self.configuration = configuration
		listContentView = UIListContentView(configuration: .valueCell())
		textField = UITextField()
		super.init(frame: .zero)
		preservesSuperviewLayoutMargins = true

		textField.textAlignment = .right
		textField.returnKeyType = .done
		textField.addAction(UIAction { [weak self] _ in
			guard let self else { return }
			textField.resignFirstResponder()
		}, for: .editingDidEndOnExit)

		listContentView.translatesAutoresizingMaskIntoConstraints = false
		textField.translatesAutoresizingMaskIntoConstraints = false
		addSubview(listContentView)
		addSubview(textField)

		NSLayoutConstraint.activate([
			listContentView.topAnchor.constraint(equalTo: topAnchor),
			listContentView.leadingAnchor.constraint(equalTo: leadingAnchor),
			listContentView.trailingAnchor.constraint(equalTo: trailingAnchor),
			listContentView.bottomAnchor.constraint(equalTo: bottomAnchor),
		])
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
