//
//  DayTrackingsController.swift
//  MoJob
//
//  Created by Martin Schneider on 23.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa
import Network


class DayTrackingsController: NSViewController {

	@IBOutlet weak var stackView: NSStackView!
	@IBOutlet weak var errorMessage: NSTextField!
	@IBOutlet weak var warningView: NSView!
	@IBOutlet weak var dateDay: NSTextField!
	@IBOutlet weak var dateMonth: NSTextField!
	@IBOutlet weak var dateYear: NSTextField!
	@IBOutlet weak var totalTimeForDay: NSTextField!
	@IBOutlet weak var trackingsStackView: TrackingsStackView!

	@IBOutlet weak var btn: NSButton!

	let monitor = NWPathMonitor()
	let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
	var _fetchedResultsControllerTrackings: NSFetchedResultsController<Tracking>? = nil
	var fetchedResultControllerTrackings: NSFetchedResultsController<Tracking> {
		if (_fetchedResultsControllerTrackings != nil) {
			return _fetchedResultsControllerTrackings!
		}

		let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()

		fetchRequest.predicate = NSPredicate(format: "date_end != nil")

		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "date_start", ascending: true)
		]

		let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsControllerTrackings = resultsController

		do {
			try _fetchedResultsControllerTrackings!.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror)")
		}

		return _fetchedResultsControllerTrackings!
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		if let trackings = fetchedResultControllerTrackings.fetchedObjects {
			trackingsStackView.reloadData(with: trackings)
		}

		if let appDelegate = (NSApp.delegate as? AppDelegate) {
			let context = appDelegate.persistentContainer.viewContext
			let notificationCenter = NotificationCenter.default
			notificationCenter.addObserver(self, selector: #selector(managedObjectContextObjectsDidChange), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: context)
			notificationCenter.addObserver(self, selector: #selector(managedObjectContextDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)
		}

		monitor.pathUpdateHandler = { path in
			DispatchQueue.main.sync {
				self.networkChanged()
			}

//			print(path.isExpensive)
		}

		let queue = DispatchQueue(label: "Monitor")
		monitor.start(queue: queue)

		warningView.wantsLayer = true
	}

	private func networkChanged() {
		let status = monitor.currentPath.status

		if (status == .satisfied) { // online
			hideWarning()

			QuoJob.isLoggedIn(
				success: { self.hideWarning() },
				failed: { errorCode in
					self.showWarning(error: "Fehlerecode: \(errorCode)")
				},
				err: { error in
					self.showWarning(error: error)
				}
			)
		} else {
			showWarning(error: "Du bist offline. Deine Trackings werden nicht an QuoJob übertragen.")
		}
	}

	func showWarning(error: String) {
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

	// MARK: - Observer

	@objc func managedObjectContextObjectsDidChange(notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }

		if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {

		}

		if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {

		}
	}

	@objc func managedObjectContextDidSave(notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }
		try! fetchedResultControllerTrackings.performFetch()
		guard let trackings = fetchedResultControllerTrackings.fetchedObjects else { return }

		if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
			trackingsStackView.reloadData(with: trackings)
		}

		if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
			trackingsStackView.reloadData(with: trackings)
		}

		if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
			trackingsStackView.reloadData(with: trackings)
		}
	}

}
