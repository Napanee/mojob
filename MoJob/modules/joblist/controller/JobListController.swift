//
//  JobListController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

protocol FilterFieldDelegate {
	func onKeyDown(keyCode: UInt16)
	func onTextChange(with string: String)
}

protocol JobItemDelegate {
	func onSelectJob()
}

protocol AddFavoriteDelegate {
	func onDismiss()
}

class JobListController: NSViewController, AddFavoriteDelegate {

	@IBOutlet weak var favoritesCollectionView: NSCollectionView!
	@IBOutlet weak var jobsCollectionView: NSCollectionView!

	@IBOutlet weak var favoritesView: NSView!
	@IBOutlet weak var stackView: NSStackView!

	@IBOutlet weak var filterField: FilterField!
	@IBOutlet weak var favoritesCollectionHeight: NSLayoutConstraint!
	@IBOutlet weak var jobsCollectionHeight: NSLayoutConstraint!

	var jobs: [Job] {
		get {
			return CoreDataHelper.jobs()
		}
	}
	var favorites: [Favorite] {
		get {
			return CoreDataHelper.favorites()
		}
	}
	var jobsFiltered: [Job] = []
	var jobListSelectedIndex: Int?
	var currentItem: JobItem? = nil
	var draggingItem: NSCollectionViewItem?
	var draggingIndexPath: IndexPath?

	var selectedJobItem: JobItem? {
		get {
			return jobsCollectionView.item(at: IndexPath(item: jobListSelectedIndex ?? 0, section: 0)) as? JobItem
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		let lessConstraint = NSLayoutConstraint(item: view, attribute: .width, relatedBy: .lessThanOrEqual, toItem: view.superview, attribute: .width, multiplier: 1, constant: 600)
		let greaterConstraint = NSLayoutConstraint(item: view, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: view.superview, attribute: .width, multiplier: 1, constant: 350)

		view.addConstraints([lessConstraint, greaterConstraint])

		jobsCollectionView.isHidden = true
		filterField.customDelegate = self

		if (jobs.count == 0) {
			favoritesView.isHidden = true
		}

		_configureCollectionView(collectionView: favoritesCollectionView)
		_configureCollectionView(collectionView: jobsCollectionView)

		favoritesCollectionView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
		favoritesCollectionView.setDraggingSourceOperationMask(NSDragOperation.move, forLocal: true)

		let context = CoreDataHelper.mainContext
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(managedObjectContextDidSave), name: .NSManagedObjectContextDidSave, object: context)
	}

	override func viewDidAppear() {
		favoritesCollectionView.collectionViewLayout?.invalidateLayout()
		jobsCollectionView.collectionViewLayout?.invalidateLayout()

		if let heightFavoritesCollection = favoritesCollectionView.collectionViewLayout?.collectionViewContentSize.height,
			let heightJobsCollection = jobsCollectionView.collectionViewLayout?.collectionViewContentSize.height {
			favoritesCollectionHeight.constant = heightFavoritesCollection
			jobsCollectionHeight.constant = heightJobsCollection
		}
	}

	override func viewWillLayout() {
		if let scrollView = view as? NSScrollView {
			scrollView.backgroundColor = NSColor.clear
			scrollView.contentView.backgroundColor = NSColor.clear
		}

		favoritesCollectionView.collectionViewLayout?.invalidateLayout()
		jobsCollectionView.collectionViewLayout?.invalidateLayout()
	}

	@objc func managedObjectContextDidSave(notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }

		if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
			if (inserts.contains(where: { $0.isKind(of: Job.self) })) {
				DispatchQueue.main.async {
					self.reloadFavorites()
					self.reloadJobs()
				}
			}
		}

		if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
			if (updates.contains(where: { $0.isKind(of: Job.self) })) {
				DispatchQueue.main.async {
					self.reloadFavorites()
					self.reloadJobs()
				}
			}
		}

		if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
			if (deletes.contains(where: { $0.isKind(of: Job.self) })) {
				DispatchQueue.main.async {
					self.reloadFavorites()
					self.reloadJobs()
				}
			}
		}
	}

	func onTextChange(with string: String) {
		guard jobs.count > 0 else { return }

		if (string.count > 0) {
			jobsCollectionView.isHidden = false
			jobsFiltered = jobs
				.filter({ $0.title!.lowercased().contains(string.lowercased()) || $0.number!.lowercased().contains(string.lowercased()) })
				.sorted(by: { $0.number! != $1.number! ? $0.number! < $1.number! : $0.title! < $1.title! })
		} else {
			jobsCollectionView.isHidden = true
			jobsFiltered = []
		}

		if let item = selectedJobItem {
			item.isHighlighted = false
			self.jobListSelectedIndex = nil
		}

		DispatchQueue.main.async {
			self.jobsCollectionView.reloadData()

			if
				let heightFavoritesCollection = self.favoritesCollectionView.collectionViewLayout?.collectionViewContentSize.height,
				let heightJobsCollection = self.jobsCollectionView.collectionViewLayout?.collectionViewContentSize.height
			{
				self.favoritesCollectionHeight.constant = heightFavoritesCollection
				self.jobsCollectionHeight.constant = heightJobsCollection
			}
		}
	}

	func onDismiss() {
		DispatchQueue.main.async {
			self.favoritesCollectionView.reloadData()

			if let heightFavoritesCollection = self.favoritesCollectionView.collectionViewLayout?.collectionViewContentSize.height {
				self.favoritesCollectionHeight.constant = heightFavoritesCollection
			}
		}
	}

	func reloadFavorites() {
		favoritesCollectionView.reloadData()
		favoritesCollectionView.collectionViewLayout?.invalidateLayout()

		if let heightFavoritesCollection = favoritesCollectionView.collectionViewLayout?.collectionViewContentSize.height {
			favoritesCollectionHeight.constant = heightFavoritesCollection
		}
	}

	func reloadJobs() {
		if jobs.count > 0 {
			favoritesView.isHidden = false

			if let heightFavoritesCollection = favoritesCollectionView.collectionViewLayout?.collectionViewContentSize.height {
				favoritesCollectionHeight.constant = heightFavoritesCollection
			}
		}

		jobsCollectionView.reloadData()

		if let heightJobsCollection = jobsCollectionView.collectionViewLayout?.collectionViewContentSize.height {
			jobsCollectionHeight.constant = heightJobsCollection
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
		let addFavoriteVC = AddFavorite(nibName: .addFavoriteNib, bundle: nil)

		let appDelegate = (NSApp.delegate as! AppDelegate)
		appDelegate.window.contentViewController?.presentAsSheet(addFavoriteVC)
	}

	@objc func onLogin() {
		let loginVC = Login(nibName: .loginNib, bundle: nil)

		let appDelegate = (NSApp.delegate as! AppDelegate)
		appDelegate.window.contentViewController?.presentAsSheet(loginVC)
	}

}

extension JobListController: FilterFieldDelegate {

	func onKeyDown(keyCode: UInt16) {
		guard [125, 126, 36].contains(keyCode) else { return }

		if (keyCode == 36) { // key enter
			guard let tracking = CoreDataHelper.createTracking(in: CoreDataHelper.currentTrackingContext) else { return }

			if let currentItem = currentItem, let itemJob = currentItem.job {
				let job = CoreDataHelper.jobs(in: CoreDataHelper.currentTrackingContext)
				tracking.job = job.first(where: { $0.id == itemJob.id })
			} else {
				tracking.custom_job = filterField.stringValue
			}

			filterField.stringValue = ""
			onTextChange(with: "")

			(NSApp.mainWindow?.windowController as? MainWindowController)?.mainSplitViewController?.showTracking()
		}

		let maxValues = jobsCollectionView.numberOfItems(inSection: 0)

		if let jobListSelectedIndex = jobListSelectedIndex,
			let item = jobsCollectionView.item(at: IndexPath(item: jobListSelectedIndex, section: 0)) as? JobItem {
			item.isHighlighted = false
		}

		if (keyCode == 125) { // cursor down
			if let jobListSelectedIndex = jobListSelectedIndex {
				self.jobListSelectedIndex = min(maxValues - 1, jobListSelectedIndex + 1)
			} else {
				self.jobListSelectedIndex = 0
			}

			if let item = selectedJobItem {
				currentItem = item
				item.isHighlighted = true
			}
		} else if (keyCode == 126) { // cursor up
			if let jobListSelectedIndex = jobListSelectedIndex, jobListSelectedIndex > 0 {
				self.jobListSelectedIndex = jobListSelectedIndex - 1

				if let item = selectedJobItem {
					item.isHighlighted = true
				}
			} else {
				self.jobListSelectedIndex = nil
			}
		}

		if
			let scrollView = view as? NSScrollView,
			let item = jobsCollectionView.item(at: IndexPath(item: self.jobListSelectedIndex ?? 0, section: 0)),
			let window = (NSApp.delegate as! AppDelegate).window
		{
			let clipView = scrollView.contentView
			let clipViewHeight = clipView.bounds.height
			let currentScrollPos = scrollView.convert(scrollView.bounds, to: clipView).minY
			let itemPos = item.view.convert(item.view.bounds, to: window.contentView)
			let itemPosMinY = itemPos.minY
			let itemPosMaxY = itemPos.maxY
			var newScrollPos: CGFloat? = nil

			if (itemPosMinY < 0) {
				newScrollPos = currentScrollPos + itemPosMinY
			} else if (itemPosMaxY > clipViewHeight) {
				newScrollPos = currentScrollPos + (itemPosMaxY - clipViewHeight)

				if (self.jobListSelectedIndex == 0) {
					// @TODO: This would be solve nicer
					newScrollPos = newScrollPos! + CGFloat(integerLiteral: 100)
				}
			}

			if let newScrollPos = newScrollPos {
				NSAnimationContext.beginGrouping()
				NSAnimationContext.current.duration = 0.5
				clipView.animator().setBoundsOrigin(NSPoint(x: 0, y: newScrollPos))
				scrollView.reflectScrolledClipView(clipView)
				NSAnimationContext.endGrouping()
			}
		}
	}

}

extension JobListController: NSCollectionViewDelegateFlowLayout {

	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
		if (collectionView == jobsCollectionView) {
			return NSSize(width: collectionView.frame.size.width, height: 30)
		}

		if (favorites.indices.contains(indexPath.item)) {
			let favorite = favorites[indexPath.item]

			if (favorite.task == nil && favorite.activity == nil) {
				return NSSize(width: collectionView.frame.size.width, height: 30)
			}
		}

		return NSSize(width: collectionView.frame.size.width, height: 45)
	}

	func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
		guard (collectionView == favoritesCollectionView) else { return false }

		return true
	}

	func collectionView(_ collectionView: NSCollectionView, writeItemsAt indexPaths: Set<IndexPath>, to pasteboard: NSPasteboard) -> Bool {
		guard (collectionView == favoritesCollectionView) else { return false }

		var archiver: Data?
		if #available(OSX 10.13, *) {
			archiver = try? NSKeyedArchiver.archivedData(withRootObject: indexPaths, requiringSecureCoding: false)
		} else {
			archiver = NSKeyedArchiver.archivedData(withRootObject: indexPaths)
		}

		if let archiver = archiver {
			let indexData = Data(archiver)
			pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: self)
			pasteboard.setData(indexData, forType: NSPasteboard.PasteboardType.string)

			return true
		}

		return false
	}

	func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexPaths: Set<IndexPath>) {
		if let indexPath = indexPaths.first,
			let item = collectionView.item(at: indexPath) {
			draggingItem = item
			draggingIndexPath = indexPath

			draggingItem?.view.isHidden = true
		}
	}

	func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, dragOperation operation: NSDragOperation) {
		if let draggingItem = draggingItem {
			draggingItem.view.isHidden = false

			if let draggingIndexPath = draggingIndexPath,
				let currentIndexPath = collectionView.indexPath(for: draggingItem),
				currentIndexPath != draggingIndexPath,
				collectionView.item(at: draggingIndexPath.item) != nil {  // guard to move once only

				collectionView.animator().moveItem(at: currentIndexPath, to: draggingIndexPath)
			}
		}

		draggingItem = nil
	}

	func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
		if let draggingItem = draggingItem {
			draggingItem.view.isHidden = false
		}

		favoritesCollectionView.collectionViewLayout?.invalidateLayout()

		draggingItem = nil

		let itemCount = collectionView.numberOfItems(inSection: 0)
		for i in 0..<itemCount {
			if let item = collectionView.item(at: IndexPath(item: i, section: 0)) as? FavoriteItem {
				item.favorite.order = Int16(i)
			}
		}

		CoreDataHelper.save()

		return true
	}

	func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
		let proposedDropIndexPath = proposedDropIndexPath.pointee

		if let draggingItem = draggingItem,
			let currentIndexPath = collectionView.indexPath(for: draggingItem),
			currentIndexPath != IndexPath(item: proposedDropIndexPath.item, section: proposedDropIndexPath.section),
			collectionView.item(at: proposedDropIndexPath.item) != nil {  // guard to move once only

			collectionView.animator().moveItem(at: currentIndexPath, to: IndexPath(item: proposedDropIndexPath.item, section: proposedDropIndexPath.section))
		}

		return .move
	}

}

extension JobListController: JobItemDelegate {

	func onSelectJob() {
		filterField.stringValue = ""
		onTextChange(with: "")
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
		if (collectionView == jobsCollectionView) {
			let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: nibNames.JobsCollectionItem), for: indexPath)

			guard let collectionViewItem = item as? JobItem else {return item}

			let job = jobsFiltered[indexPath.item]
			collectionViewItem.job = job
			collectionViewItem.delegate = self
			collectionViewItem.textField?.stringValue = "\(job.number!) - \(job.title!)"

			return collectionViewItem
		}

		let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: nibNames.FavoritesCollectionItem), for: indexPath)

		guard let collectionViewItem = item as? FavoriteItem else {return item}

		let favorite = favorites[indexPath.item]
		collectionViewItem.favorite = favorite

		return collectionViewItem
	}

}
