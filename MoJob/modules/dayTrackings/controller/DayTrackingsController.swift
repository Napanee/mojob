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
	@IBOutlet weak var warningStackView: NSStackView!
	@IBOutlet weak var dateDay: NSTextField!
	@IBOutlet weak var dateMonth: NSTextField!
	@IBOutlet weak var dateYear: NSTextField!
	@IBOutlet weak var totalTimeForDay: NSTextField!
	@IBOutlet weak var trackingsStackView: TrackingsStackView!
	@IBOutlet weak var loginButton: NSButton!

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
		}

		let queue = DispatchQueue(label: "Monitor")
		monitor.start(queue: queue)

		warningView.wantsLayer = true

		NotificationCenter.default.addObserver(self, selector: #selector(onSessionUpdate(notification:)), name: NSNotification.Name(rawValue: "updateSession"), object: nil)
	}

	private func networkChanged() {
		let status = monitor.currentPath.status
		hideWarning()

		if (status == .satisfied) { // online
			QuoJob.shared.checkLoginStatus().catch { error in
				if (error.localizedDescription == errorMessages.sessionProblem) {
					QuoJob.shared.loginWithKeyChain().catch { error in
						self.loginButton.isHidden = false
					}
				}

				self.showWarning(error: error.localizedDescription)
			}
		} else { // offline
			showWarning(error: errorMessages.offline)
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
		loginButton.isHidden = true

		if let warningView = stackView.subviews.first(where: { $0.isEqual(warningView) }) {
			warningView.removeFromSuperview()
		}
	}

	@objc private func onSessionUpdate(notification: NSNotification) {
		hideWarning()
	}

	@IBAction func loginButton(_ sender: NSButton) {
		let loginVC = Login(nibName: "Login", bundle: nil)

		let appDelegate = (NSApp.delegate as! AppDelegate)
		appDelegate.window.contentViewController?.presentAsSheet(loginVC)
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
