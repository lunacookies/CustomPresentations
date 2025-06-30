import UIKit

final class RootViewController: UICollectionViewController {
	private static let items = [
		Item(title: "Custom Sheet") { CustomSheetExampleViewController() },
	]

	private let cellRegistration =
		UICollectionView.CellRegistration<UICollectionViewListCell, Void> { cell, indexPath, _ in
			var contentConfiguration = UIListContentConfiguration.cell()
			contentConfiguration.text = RootViewController.items[indexPath.item].title
			cell.contentConfiguration = contentConfiguration
			cell.accessories = [.disclosureIndicator()]
		}

	init() {
		super.init(collectionViewLayout: UICollectionViewCompositionalLayout { _, layoutEnvironment in
			let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
			return .list(using: configuration, layoutEnvironment: layoutEnvironment)
		})
	}

	@available(*, unavailable)
	required init?(coder _: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "All Presentations"
		navigationItem.backButtonTitle = "All"
		navigationController?.navigationBar.prefersLargeTitles = true
	}

	override func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
		Self.items.count
	}

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let viewController = Self.items[indexPath.item].viewControllerProvider()
		viewController.navigationItem.largeTitleDisplayMode = .never
		show(viewController, sender: nil)
	}

	override func collectionView(
		_: UICollectionView,
		cellForItemAt indexPath: IndexPath,
	) -> UICollectionViewCell {
		collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: ())
	}

	private struct Item {
		let title: String
		let viewControllerProvider: () -> UIViewController
	}
}
