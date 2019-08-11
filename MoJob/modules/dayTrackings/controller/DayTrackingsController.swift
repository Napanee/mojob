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

	private var currentDate: Date = Date()
	private var observer: NSObjectProtocol?

	override func viewDidLoad() {
		super.viewDidLoad()

		if let trackings = CoreDataHelper.trackings(for: currentDate) {
			trackingsStackView.reloadData(with: trackings)
		}

		changeDate(with: currentDate)

		let context = CoreDataHelper.context
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(managedObjectContextDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)

		NotificationCenter.default.addObserver(self, selector: #selector(calendarDayChanged), name: .NSCalendarDayChanged, object: nil)

		observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "calendar:changedDate"), object: nil, queue: nil, using: { notification in
			guard notification.name == .init("calendar:changedDate"), let date = notification.object as? [String: Any], let day = date["day"] as? Date else{ return }

			self.currentDate = day
			self.changeDate(with: day)
		})
	}

	private func changeDate(with date: Date) {
		DispatchQueue.main.async {
			self.dateDay.stringValue = date.day
			self.dateMonth.stringValue = date.month
			self.dateYear.stringValue = date.year

			if let trackings = CoreDataHelper.trackings(for: date) {
				self.trackingsStackView.reloadData(with: trackings)

				let sum = trackings.map({ $0.date_end!.timeIntervalSince($0.date_start!) }).reduce(0.0, { $0 + $1 })
				let formatter = DateComponentsFormatter()
				formatter.unitsStyle = .abbreviated
				formatter.zeroFormattingBehavior = .pad
				formatter.allowedUnits = [.hour, .minute]

				self.totalTimeForDay.stringValue = formatter.string(from: sum)!
			}
		}
	}

	@objc func calendarDayChanged() {
		changeDate(with: Date())
	}

	@IBAction func loginButton(_ sender: NSButton) {
		let loginVC = Login(nibName: .loginNib, bundle: nil)

		let appDelegate = (NSApp.delegate as! AppDelegate)
		appDelegate.window.contentViewController?.presentAsSheet(loginVC)
	}

	// MARK: - Observer

	@objc func managedObjectContextDidSave(notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }
		guard let trackings = CoreDataHelper.trackings(for: currentDate) else { return }

		if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
			trackingsStackView.reloadData(with: trackings)
			changeDate(with: currentDate)
		}

		if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
			trackingsStackView.reloadData(with: trackings)
			changeDate(with: currentDate)
		}

		if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
			trackingsStackView.reloadData(with: trackings)
			changeDate(with: currentDate)
		}
	}

}
