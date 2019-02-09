//
//  JobListController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class JobListController: NSViewController {

	@IBOutlet weak var favoritesCollectionView: NSCollectionView!
	@IBOutlet weak var jobsCollectionView: NSCollectionView!

	@IBOutlet weak var bottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var favoritesCollectionheight: NSLayoutConstraint!
	@IBOutlet weak var jobsCollectionHeight: NSLayoutConstraint!

	let favorites: [String] = ["Foo", "bar"]
	let jobs: [String] = ["Foo", "bar", "Lorem", "Ipsum", "Noch was", "Darunter", "Und....", "noch einer", "damit das", "wirklich hoch", "wird... ;("]

	override func viewDidLoad() {
        super.viewDidLoad()

		_configureCollectionViewFirst()
		_configureCollectionViewSecond()
    }

	override func viewDidAppear() {
		if let firstHeight = favoritesCollectionView.collectionViewLayout?.collectionViewContentSize.height,
			let secondHeight = jobsCollectionView.collectionViewLayout?.collectionViewContentSize.height {
			favoritesCollectionheight.constant = firstHeight
			jobsCollectionHeight.constant = secondHeight

			let diff = view.frame.height - firstHeight - secondHeight

			bottomConstraint.constant = diff
		}
	}

	final private func _configureCollectionViewFirst() {
		let padding = NSEdgeInsets.init(top: 5, left: 0, bottom: 5, right: 0)
		let flowLayout = NSCollectionViewFlowLayout()
		flowLayout.sectionInset = padding
		flowLayout.minimumLineSpacing = 5.0

		favoritesCollectionView.collectionViewLayout = flowLayout
	}

	final private func _configureCollectionViewSecond() {
		let padding = NSEdgeInsets.init(top: 5, left: 0, bottom: 5, right: 0)
		let flowLayout = NSCollectionViewFlowLayout()
		flowLayout.sectionInset = padding
		flowLayout.minimumLineSpacing = 5.0

		jobsCollectionView.collectionViewLayout = flowLayout
	}

}

extension JobListController: NSCollectionViewDelegateFlowLayout {

//	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
//		return NSSize(width: 1000, height: 29)
//	}

	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
		if (collectionView == jobsCollectionView) {
			return NSSize(width: collectionView.frame.size.width, height: 46)
		}

		return NSSize(width: collectionView.frame.size.width, height: 46)
	}

}

extension JobListController: NSCollectionViewDataSource {

	func numberOfSections(in collectionView: NSCollectionView) -> Int {
		return 1
	}

	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		if (collectionView == jobsCollectionView) {
			return jobs.count
		}

		return favorites.count
	}

	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		if (collectionView == jobsCollectionView) {
			let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: nibNames.JobsCollectionItem), for: indexPath)

			guard let collectionViewItem = item as? JobItem else {return item}

			collectionViewItem.textField?.stringValue = jobs[indexPath.item]

			return collectionViewItem
		}

		let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: nibNames.FavoritesCollectionItem), for: indexPath)

		guard let collectionViewItem = item as? FavoriteItem else {return item}

		collectionViewItem.textField?.stringValue = favorites[indexPath.item]

		return collectionViewItem
	}

}
