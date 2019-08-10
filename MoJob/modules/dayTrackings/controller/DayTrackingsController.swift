//
//  DayTrackingsController.swift
//  MoJob
//
//  Created by Martin Schneider on 23.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


class DayTrackingsController: NSViewController {

	@IBOutlet weak var stackView: NSStackView!
	@IBOutlet weak var dateDay: NSTextField!
	@IBOutlet weak var dateMonth: NSTextField!
	@IBOutlet weak var dateYear: NSTextField!
	@IBOutlet weak var totalTimeForDay: NSTextField!
	@IBOutlet weak var trackingsStackView: TrackingsStackView!

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
				NSPredicate(format: "date_start >= %@ AND date_start < %@", argumentArray: [todayStart, todayEnd]),
				NSPredicate(format: "date_end >= %@ AND date_end < %@", argumentArray: [todayStart, todayEnd])
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

		let today = Date()
		dateDay.stringValue = today.day
		dateMonth.stringValue = today.month
		dateYear.stringValue = today.year

		NotificationCenter.default.addObserver(self, selector: #selector(calendarDayChanged), name: .NSCalendarDayChanged, object: nil)
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
