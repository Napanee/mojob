//
//  JobListController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class JobListController: NSViewController, NSTextFieldDelegate {

	@IBOutlet weak var favoritesCollectionView: NSCollectionView!
	@IBOutlet weak var jobsCollectionView: NSCollectionView!

	@IBOutlet weak var filterField: FilterField!
	@IBOutlet weak var favoritesCollectionHeight: NSLayoutConstraint!
	@IBOutlet weak var jobsCollectionHeight: NSLayoutConstraint!

	let favorites: [String] = ["Foo", "bar"]
	let jobsAll: [String] = ["Job2", "Job2 noc", "foo", "ein ander job", "ein großer job2", "Noch was", "Darunter", "Und....", "noch einer", "damit das", "wirklich hoch", "wird... ;("]
	var jobsFiltered: [String] = []

	override func viewDidLoad() {
        super.viewDidLoad()

		jobsCollectionView.isHidden = true

		_configureCollectionView(collectionView: favoritesCollectionView)
		_configureCollectionView(collectionView: jobsCollectionView)
    }

	override func viewDidAppear() {
		if let heightFavoritesCollection = favoritesCollectionView.collectionViewLayout?.collectionViewContentSize.height,
			let heightJobsCollection = jobsCollectionView.collectionViewLayout?.collectionViewContentSize.height {
			favoritesCollectionHeight.constant = heightFavoritesCollection
			jobsCollectionHeight.constant = heightJobsCollection
		}
	}

	override func viewWillLayout() {
		favoritesCollectionView.collectionViewLayout?.invalidateLayout()
		jobsCollectionView.collectionViewLayout?.invalidateLayout()
	}

	func controlTextDidChange(_ obj: Notification) {
		if let textField = obj.object as? NSTextField {
			if (textField.stringValue.count == 0) {
				jobsCollectionView.isHidden = true
				jobsFiltered = []
			} else if (textField.stringValue.count > 0) {
				jobsCollectionView.isHidden = false
				jobsFiltered = jobsAll.filter({ $0.lowercased().contains(textField.stringValue.lowercased()) })
			}

			jobsCollectionView.reloadData()

			if let heightFavoritesCollection = favoritesCollectionView.collectionViewLayout?.collectionViewContentSize.height,
				let heightJobsCollection = jobsCollectionView.collectionViewLayout?.collectionViewContentSize.height {
				favoritesCollectionHeight.constant = heightFavoritesCollection
				jobsCollectionHeight.constant = heightJobsCollection
			}
		}
	}

	final private func _configureCollectionView(collectionView: NSCollectionView) {
		let padding = NSEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
		let flowLayout = NSCollectionViewFlowLayout()
		flowLayout.sectionInset = padding
		flowLayout.minimumLineSpacing = 0

		collectionView.collectionViewLayout = flowLayout
	}

	@IBAction func addFavorit(_ sender: NSButton) {

	}

}

extension JobListController: NSCollectionViewDelegateFlowLayout {

	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
		if (collectionView == jobsCollectionView) {
			return NSSize(width: collectionView.frame.size.width, height: 30)
		}

		return NSSize(width: collectionView.frame.size.width, height: 30)
	}

}

extension JobListController: NSCollectionViewDataSource {

	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		if (collectionView == jobsCollectionView) {
			return jobsFiltered.count
		}

		return favorites.count
	}

	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		print(1)
		if (collectionView == jobsCollectionView) {
			let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: nibNames.JobsCollectionItem), for: indexPath)

			guard let collectionViewItem = item as? JobItem else {return item}

			collectionViewItem.textField?.stringValue = jobsFiltered[indexPath.item]

			return collectionViewItem
		}

		let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: nibNames.FavoritesCollectionItem), for: indexPath)

		guard let collectionViewItem = item as? FavoriteItem else {return item}

		collectionViewItem.textField?.stringValue = favorites[indexPath.item]

		return collectionViewItem
	}

}
