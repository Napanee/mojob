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

protocol FavoritesItemDelegate {
	func onDeleteFavorite()
}

protocol AddFavoriteDelegate {
	func onDismiss()
}

class JobListController: NSViewController, AddFavoriteDelegate {

	@IBOutlet weak var favoritesCollectionView: NSCollectionView!
	@IBOutlet weak var jobsCollectionView: NSCollectionView!

	@IBOutlet weak var favoritesView: NSView!
	@IBOutlet weak var stackView: NSStackView!
	@IBOutlet weak var errorMessage: NSTextField!
	@IBOutlet weak var warningView: NSView!
	@IBOutlet weak var warningStackView: NSStackView!
	@IBOutlet weak var warningButton: NSButton!

	@IBOutlet weak var filterField: FilterField!
	@IBOutlet weak var favoritesCollectionHeight: NSLayoutConstraint!
	@IBOutlet weak var jobsCollectionHeight: NSLayoutConstraint!

	var favorites: [Job] = []
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

	let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
	var _fetchedResultsControllerJobs: NSFetchedResultsController<Job>? = nil
	var fetchedResultControllerJobs: NSFetchedResultsController<Job> {
		if (_fetchedResultsControllerJobs != nil) {
			return _fetchedResultsControllerJobs!
		}

		let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "assigned == true")

		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "type", ascending: true)
		]

		let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsControllerJobs = resultsController

		do {
			try _fetchedResultsControllerJobs!.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror)")
		}

		return _fetchedResultsControllerJobs!
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		jobsCollectionView.isHidden = true
		filterField.customDelegate = self

		if let jobs = fetchedResultControllerJobs.fetchedObjects {
			favorites = jobs.filter({ $0.isFavorite })

			if (jobs.count == 0) {
				favoritesView.isHidden = true
			}
		}

		_configureCollectionView(collectionView: favoritesCollectionView)
		_configureCollectionView(collectionView: jobsCollectionView)

		favoritesCollectionView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
		favoritesCollectionView.setDraggingSourceOperationMask(NSDragOperation.move, forLocal: true)

		warningView.wantsLayer = true
		warningButton.target = self
		warningButton.action = #selector(onSync)

		if (fetchedResultControllerJobs.fetchedObjects?.count == 0) {
			showWarning(error: "Es sind keine Jobs vorhanden. Jetzt mit QuoJob synchronisieren?")
		}

		if let appDelegate = (NSApp.delegate as? AppDelegate) {
			let context = appDelegate.persistentContainer.viewContext
			let notificationCenter = NotificationCenter.default
			notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: context)
		}

		NotificationCenter.default.addObserver(self, selector: #selector(onSessionUpdate(notification:)), name: NSNotification.Name(rawValue: "updateSession"), object: nil)
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

	@objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }

		if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
			if let updateValues = updates.first?.changedValues() {
				let keys = updateValues.keys
				if (keys.contains("color")) {
					favoritesCollectionView.reloadData()
				}
			}
		}
	}

	func showWarning(error: String) {
		if (QuoJob.shared.sessionId == "") {
			warningButton.image = NSImage(named: "login")
			warningButton.title = "Jetzt einloggen"
			warningButton.action = #selector(onLogin)
		}

		errorMessage.stringValue = error
		warningView.layer?.backgroundColor = NSColor.systemYellow.withAlphaComponent(0.75).cgColor
		stackView.insertView(warningView, at: 1, in: .top)

		let leftConstraint = NSLayoutConstraint(item: warningView, attribute: .leading, relatedBy: .equal, toItem: warningView.superview, attribute: .leading, multiplier: 1, constant: 0)
		let rightConstraint = NSLayoutConstraint(item: warningView, attribute: .trailing, relatedBy: .equal, toItem: warningView.superview, attribute: .trailing, multiplier: 1, constant: 0)
		stackView.addConstraints([leftConstraint, rightConstraint])
	}

	func hideWarning() {
		if let warningView = stackView.subviews.first(where: { $0.isEqual(warningView) }) {
			warningView.removeFromSuperview()
		}
	}

	func onTextChange(with string: String) {
		guard let jobs = fetchedResultControllerJobs.fetchedObjects else { return }

		if (string.count > 0) {
			jobsCollectionView.isHidden = false
			jobsFiltered = jobs.filter({ $0.title!.lowercased().contains(string.lowercased()) || $0.number!.lowercased().contains(string.lowercased()) })
		} else {
			jobsCollectionView.isHidden = true
			jobsFiltered = []
		}

		if let item = selectedJobItem {
			item.isHighlighted = false
			self.jobListSelectedIndex = nil
		}

		jobsCollectionView.reloadData()

		if let heightFavoritesCollection = favoritesCollectionView.collectionViewLayout?.collectionViewContentSize.height,
			let heightJobsCollection = jobsCollectionView.collectionViewLayout?.collectionViewContentSize.height {
			favoritesCollectionHeight.constant = heightFavoritesCollection
			jobsCollectionHeight.constant = heightJobsCollection
		}
	}

	func onDismiss() {
		if let jobs = fetchedResultControllerJobs.fetchedObjects {
			favorites = jobs.filter({ $0.isFavorite })
		}

		favoritesCollectionView.reloadData()

		if let heightFavoritesCollection = favoritesCollectionView.collectionViewLayout?.collectionViewContentSize.height {
			favoritesCollectionHeight.constant = heightFavoritesCollection
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
		let addFavoriteVC = AddFavorite(nibName: "AddFavorite", bundle: nil)
		addFavoriteVC.delegate = self

		let appDelegate = (NSApp.delegate as! AppDelegate)
		appDelegate.window.contentViewController?.presentAsSheet(addFavoriteVC)
	}

	@objc func onLogin() {
		let loginVC = Login(nibName: "Login", bundle: nil)

		let appDelegate = (NSApp.delegate as! AppDelegate)
		appDelegate.window.contentViewController?.presentAsSheet(loginVC)
	}

	@objc func onSync() {
		QuoJob.shared.syncData()
			.done {
				self.warningView.isHidden = true

				try! self.fetchedResultControllerJobs.performFetch()

				if let jobs = self.fetchedResultControllerJobs.fetchedObjects {
					self.favorites = jobs.filter({ $0.isFavorite })

					if (jobs.count > 0) {
						self.favoritesView.isHidden = false
					}
				}
			}
			.catch { error in
				//Handle error or give feedback to the user
				print(error.localizedDescription)
			}
	}

	@objc private func onSessionUpdate(notification: NSNotification) {
		if (warningView.isHidden == false) {
			warningButton.image = NSImage(named: "reload")
			warningButton.title = "Jetzt synchronisieren"
			warningButton.action = #selector(onSync)
		}
	}

}

extension JobListController: FilterFieldDelegate {

	func onKeyDown(keyCode: UInt16) {
		guard [125, 126, 36].contains(keyCode) else { return }

		if (keyCode == 36) { // key enter
			if let appDelegate = NSApp.delegate as? AppDelegate, let window = appDelegate.window, let contentViewController = window.contentViewController as? SplitViewController {
				if let currentItem = currentItem, let job = currentItem.job {
					appDelegate.currentTracking(job: job)
				} else {
					appDelegate.currentTracking(jobTitle: filterField.stringValue)
				}

				contentViewController.showTracking()
			}
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

		return NSSize(width: collectionView.frame.size.width, height: 30)
	}

	func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexPaths: Set<IndexPath>, with event: NSEvent) -> Bool {
		guard (collectionView == favoritesCollectionView) else { return false }

		return true
	}

	func collectionView(_ collectionView: NSCollectionView, writeItemsAt indexPaths: Set<IndexPath>, to pasteboard: NSPasteboard) -> Bool {
		guard (collectionView == favoritesCollectionView) else { return false }

		if let archiver = try? NSKeyedArchiver.archivedData(withRootObject: indexPaths, requiringSecureCoding: false) {
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

		draggingItem = nil

		let itemCount = collectionView.numberOfItems(inSection: 0)
		for i in 0..<itemCount {
			if let item = collectionView.item(at: IndexPath(item: i, section: 0)) as? FavoriteItem {
				item.job.favoriteOrder = Int16(i)
			}
		}

		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
		do {
			try context.save()
		} catch let error {
			print(error)
		}

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

extension JobListController: NSCollectionViewDataSource, FavoritesItemDelegate {

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
			collectionViewItem.textField?.stringValue = "\(job.number!) - \(job.title!)"

			return collectionViewItem
		}

		let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: nibNames.FavoritesCollectionItem), for: indexPath)

		guard let collectionViewItem = item as? FavoriteItem else {return item}

		let job = favorites[indexPath.item]
		collectionViewItem.job = job
		collectionViewItem.delegate = self
		collectionViewItem.textField?.stringValue = "\(job.number!) - \(job.title!)"

		return collectionViewItem
	}

	func onDeleteFavorite() {
		if let jobs = fetchedResultControllerJobs.fetchedObjects {
			favorites = jobs.filter({ $0.isFavorite })
		}

		favoritesCollectionView.reloadData()

		if let heightFavoritesCollection = favoritesCollectionView.collectionViewLayout?.collectionViewContentSize.height {
			favoritesCollectionHeight.constant = heightFavoritesCollection
		}
	}

}
