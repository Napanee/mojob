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

class JobListController: NSViewController {

	@IBOutlet weak var favoritesCollectionView: NSCollectionView!
	@IBOutlet weak var jobsCollectionView: NSCollectionView!

	@IBOutlet weak var stackView: NSStackView!
	@IBOutlet weak var errorMessage: NSTextField!
	@IBOutlet weak var warningView: NSView!
	@IBOutlet weak var warningStackView: NSStackView!
	@IBOutlet weak var warningButton: NSButton!

	@IBOutlet weak var filterField: FilterField!
	@IBOutlet weak var favoritesCollectionHeight: NSLayoutConstraint!
	@IBOutlet weak var jobsCollectionHeight: NSLayoutConstraint!

	let favorites: [String] = ["Foo", "bar"]
	let jobsAll: [String] = ["ob2", "Job2 noc", "fjoo", "ein ander job", "ein großer job2", "Noch wasj", "Daruntejr", "Ujnd....", "noch einerj", "damit dasj", "wirklich hochj", "wjird... ;("]
	var jobsFiltered: [String] = []
	var jobListSelectedIndex: Int?

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

		_configureCollectionView(collectionView: favoritesCollectionView)
		_configureCollectionView(collectionView: jobsCollectionView)

		warningView.wantsLayer = true
		warningButton.target = self
		warningButton.action = #selector(onSync)

		if (fetchedResultControllerJobs.fetchedObjects?.count == 0) {
			showWarning(error: "Es sind keine Jobs vorhanden. Jetzt mit QuoJob synchronisieren?")
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
		if (string.count > 0) {
			jobsCollectionView.isHidden = false
			jobsFiltered = jobsAll.filter({ $0.lowercased().contains(string.lowercased()) })
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

	final private func _configureCollectionView(collectionView: NSCollectionView) {
		let padding = NSEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
		let flowLayout = NSCollectionViewFlowLayout()
		flowLayout.sectionInset = padding
		flowLayout.minimumLineSpacing = 0

		collectionView.collectionViewLayout = flowLayout
	}

	@IBAction func addFavorit(_ sender: NSButton) {

	}

	@objc func onLogin() {
		let loginVC = Login(nibName: "Login", bundle: nil)

		let appDelegate = (NSApp.delegate as! AppDelegate)
		appDelegate.window.contentViewController?.presentAsSheet(loginVC)
	}

	@objc func onSync() {
		QuoJob.shared.syncData()
			.done {
				print("done!")
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
			let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
			let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: context)
			let tracking = NSManagedObject(entity: entity!, insertInto: context)
			let trackingValues = [
				"date_start": Calendar.current.date(bySetting: .second, value: 0, of: Date()) as Any,
				"custom_job": filterField.stringValue as Any
			]
			tracking.setValuesForKeys(trackingValues)

			do {
				try context.save()

				let window = (NSApp.delegate as! AppDelegate).window
				if let contentViewController = window?.contentViewController as? SplitViewController {
					contentViewController.showTracking()
				}
			} catch let error {
				print(error)
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

			collectionViewItem.textField?.stringValue = jobsFiltered[indexPath.item]

			return collectionViewItem
		}

		let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: nibNames.FavoritesCollectionItem), for: indexPath)

		guard let collectionViewItem = item as? FavoriteItem else {return item}

		collectionViewItem.textField?.stringValue = favorites[indexPath.item]

		return collectionViewItem
	}

}
