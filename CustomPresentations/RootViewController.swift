import UIKit

final class RootViewController: UICollectionViewController {
	private static let items = ["Foo", "Bar", "Baz"]

	private let cellRegistration =
		UICollectionView.CellRegistration<UICollectionViewListCell, Void> { cell, indexPath, _ in
			var contentConfiguration = UIListContentConfiguration.cell()
			contentConfiguration.text = RootViewController.items[indexPath.item]
			cell.contentConfiguration = contentConfiguration
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
		title = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
		navigationController?.navigationBar.prefersLargeTitles = true
	}

	override func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
		Self.items.count
	}

	override func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		collectionView.deselectItem(at: indexPath, animated: true)
	}

	override func collectionView(
		_: UICollectionView,
		cellForItemAt indexPath: IndexPath,
	) -> UICollectionViewCell {
		collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: ())
	}
}
