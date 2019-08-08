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
	let context = CoreDataHelper.shared.persistentContainer.viewContext
	var _fetchedResultsControllerTrackings: NSFetchedResultsController<Tracking>? = nil
	var fetchedResultControllerTrackings: NSFetchedResultsController<Tracking> {
		if (_fetchedResultsControllerTrackings != nil) {
			return _fetchedResultsControllerTrackings!
		}

		let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()

		var compoundPredicates = [NSPredicate]()
		compoundPredicates.append(NSPredicate(format: "date_end != nil"))

		if
			let todayStart = Date().startOfDay,
			let todayEnd = Date().endOfDay
		{
			let compound = NSCompoundPredicate(orPredicateWithSubpredicates: [
				NSPredicate(format: "date_start >= %@ AND date_start <= %@", argumentArray: [todayStart, todayEnd]),
				NSPredicate(format: "date_end >= %@ AND date_end <= %@", argumentArray: [todayStart, todayEnd])
			])
			compoundPredicates.append(compound)
		}

		fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicates)

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

			let sum = trackings.map({ $0.date_end!.timeIntervalSince($0.date_start!) }).reduce(0.0, { $0 + $1 })
			totalTimeForDay.stringValue = secondsToHoursMinutesSeconds(sec: Int(sum))
		}

		let context = CoreDataHelper.shared.persistentContainer.viewContext
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(managedObjectContextDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)

		monitor.pathUpdateHandler = { path in
			DispatchQueue.main.sync {
				self.networkChanged()
			}
		}

		warningView.wantsLayer = true

		let today = Date()
		dateDay.stringValue = today.day
		dateMonth.stringValue = today.month
		dateYear.stringValue = today.year

		NotificationCenter.default.addObserver(self, selector: #selector(onSessionUpdate(notification:)), name: NSNotification.Name(rawValue: "updateSession"), object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(calendarDayChanged), name: .NSCalendarDayChanged, object: nil)
	}

	override func viewDidAppear() {
		let queue = DispatchQueue(label: "Monitor")
		monitor.start(queue: queue)
	}

	override func viewDidDisappear() {
		monitor.cancel()
	}

	private func networkChanged() {
		let status = monitor.currentPath.status
		hideWarning()

		if (status == .satisfied) { // online
			QuoJob.shared.checkLoginStatus().catch { error in
				if (error.localizedDescription == errorMessages.sessionProblem) {
					QuoJob.shared.loginWithKeyChain().catch { error in
						self.loginButton.isHidden = false
						self.showWarning(error: error.localizedDescription)
					}
				}
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

	@objc func calendarDayChanged() {
		DispatchQueue.main.async {
			let today = Date()
			self.dateDay.stringValue = today.day
			self.dateMonth.stringValue = today.month
			self.dateYear.stringValue = today.year

			self._fetchedResultsControllerTrackings = nil
			if let trackings = self.fetchedResultControllerTrackings.fetchedObjects {
				self.trackingsStackView.reloadData(with: trackings)

				let sum = trackings.map({ $0.date_end!.timeIntervalSince($0.date_start!) }).reduce(0.0, { $0 + $1 })
				self.totalTimeForDay.stringValue = secondsToHoursMinutesSeconds(sec: Int(sum))
			}
		}
	}

	@IBAction func loginButton(_ sender: NSButton) {
		let loginVC = Login(nibName: .loginNib, bundle: nil)

		let appDelegate = (NSApp.delegate as! AppDelegate)
		appDelegate.window.contentViewController?.presentAsSheet(loginVC)
	}

	// MARK: - Observer

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

		let sum = trackings.map({ $0.date_end!.timeIntervalSince($0.date_start!) }).reduce(0.0, { $0 + $1 })
		totalTimeForDay.stringValue = secondsToHoursMinutesSeconds(sec: Int(sum))
	}

}
