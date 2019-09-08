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
	@IBOutlet weak var graphView: GraphView!

	private var currentDate: Date = Date().startOfDay!
	private var observer: NSObjectProtocol?
	private var filteredJob: Job?

	override func viewDidLoad() {
		super.viewDidLoad()

		changeDate(with: currentDate)

		let context = CoreDataHelper.mainContext
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(managedObjectContextDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)
		notificationCenter.addObserver(self, selector: #selector(calendarDayChanged), name: .NSCalendarDayChanged, object: nil)

		notificationCenter.addObserver(forName: NSNotification.Name(rawValue: "counter:tick"), object: nil, queue: nil, using: { notification in
			guard notification.name == .init("counter:tick") else { return }

			self.changeDate(with: self.currentDate)
		})

		observer = notificationCenter.addObserver(forName: NSNotification.Name(rawValue: "calendar:changedDate"), object: nil, queue: nil, using: { notification in
			guard notification.name == .init("calendar:changedDate"), let date = notification.object as? [String: Any], let day = date["day"] as? Date else { return }

			self.filteredJob = date["job"] as? Job
			self.changeDate(with: day)
		})
	}

	private func changeDate(with date: Date) {
		DispatchQueue.main.async {
			self.currentDate = date

			self.dateDay.stringValue = date.day
			self.dateMonth.stringValue = date.month
			self.dateYear.stringValue = date.year

			if let trackings = CoreDataHelper.trackings(from: date, byAdding: .day, and: self.filteredJob) {
				self.graphView.trackings = trackings
				let calendar = Calendar.current
				self.trackingsStackView.currentDate = calendar.isDateInToday(date) ? Date() : date

				DispatchQueue.main.async {
					self.trackingsStackView.reloadData(with: trackings)
				}

				let sum = CoreDataHelper.seconds(from: date.startOfDay!, byAdding: .day, and: self.filteredJob)
				let formatter = DateComponentsFormatter()
				formatter.unitsStyle = .abbreviated
				formatter.zeroFormattingBehavior = .pad
				formatter.allowedUnits = [.hour, .minute]

				self.totalTimeForDay.stringValue = formatter.string(from: sum ?? 0)!
			}
		}
	}

	@objc func calendarDayChanged() {
		changeDate(with: Date().startOfDay!)
	}

	// MARK: - Observer

	@objc func managedObjectContextDidSave(notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }
		guard let trackings = CoreDataHelper.trackings(from: currentDate, byAdding: .day, and: filteredJob) else { return }

		if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
			graphView.trackings = trackings
			DispatchQueue.main.async {
				self.trackingsStackView.reloadData(with: trackings)
			}
			changeDate(with: currentDate)
		}

		if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
			graphView.trackings = trackings
			DispatchQueue.main.async {
				self.trackingsStackView.reloadData(with: trackings)
			}
			changeDate(with: currentDate)
		}

		if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
			graphView.trackings = trackings
			DispatchQueue.main.async {
				self.trackingsStackView.reloadData(with: trackings)
			}
			changeDate(with: currentDate)
		}
	}

}
