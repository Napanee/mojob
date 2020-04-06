//
//  EditorController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

protocol DateFieldDelegate {
	func getFromMonth() -> Int?
	func getFromYear() -> Int?
}

class EditorController: QuoJobSelections {

	override var formIsValid: Bool {
		get {
			if (tracking != nil) {
				return super.formIsValid
			}

			let index = activitySelect.indexOfSelectedItem

			if (index >= 0 && activities.count > index) {
				let activity = activities[index]
				let hasJob = jobSelect.stringValue.count > 0 || jobSelect.indexOfSelectedItem >= 0 || activity.nfc
				let hasTask = tasks.count == 0 || taskSelect.indexOfSelectedItem >= 0 || activity.nfc
				return hasJob && hasTask
			}

			return false
		}
		set {
			saveButton.isEnabled = newValue && (tracking != nil ? super.formIsValid : formIsValid)
		}
	}

	override var tracking: Tracking? {
		didSet {
			initEditor()

			saveButton.isEnabled = formIsValid
			deleteButton.isHidden = tracking?.managedObjectContext == CoreDataHelper.backgroundContext
		}
	}

	@IBOutlet weak var saveButton: NSButton!
	@IBOutlet weak var deleteButton: NSButton!
	@IBOutlet weak var taskHours: NSTextField!

	override func viewDidLoad() {
		super.viewDidLoad()

		initEditor()

		delegate = self
		fromDay.dateDelegate = self
		fromMonth.dateDelegate = self
		fromYear.dateDelegate = self
		fromHour.dateDelegate = self
		fromMinute.dateDelegate = self
		untilHour.dateDelegate = self
		untilMinute.dateDelegate = self

		saveButton.isEnabled = formIsValid
		deleteButton.isHidden = tracking?.managedObjectContext == CoreDataHelper.backgroundContext
	}

	@IBAction func deleteTracking(_ sender: NSButton) {
		tracking?.delete()

		removeFromParent()
	}
	
	@IBAction func cancel(_ sender: NSButton) {
		tracking?.managedObjectContext?.rollback()

		removeFromParent()
	}

	@IBAction func save(_ sender: NSButton) {
		if tracking == nil {
			guard let tracking = CoreDataHelper.createTracking() else { return }

			var indexJob = jobSelect.indexOfSelectedItem
			let valueJob = jobSelect.stringValue.lowercased()
			let indexTask = taskSelect.indexOfSelectedItem
			let indexActivity = activitySelect.indexOfSelectedItem

			if (indexJob < 0 && valueJob != "") {
				indexJob = jobs.firstIndex(where: { $0.fullTitle.lowercased() == valueJob }) ?? -1
			}

			if (indexJob >= 0 && jobs.count > indexJob) {
				tracking.job = jobs[indexJob]
			} else {
				tracking.custom_job = jobSelect.stringValue
			}

			if (indexTask >= 0 && tasks.count > indexTask) {
				tracking.task = tasks[indexTask]
			}

			if (indexActivity >= 0 && activities.count > indexActivity) {
				tracking.activity = activities[indexActivity]
			}

			tracking.comment = comment.stringValue.count > 0 ? comment.stringValue : nil

			let dateComponentsStart = DateComponents(year: Int(fromYear.stringValue), month: Int(fromMonth.stringValue), day: Int(fromDay.stringValue), hour: Int(fromHour.stringValue), minute: Int(fromMinute.stringValue))
			if let dateStart = Calendar.current.date(from: dateComponentsStart) {
				tracking.date_start = dateStart
			}

			let dateComponentsUntil = DateComponents(year: Int(fromYear.stringValue), month: Int(fromMonth.stringValue), day: Int(fromDay.stringValue), hour: Int(untilHour.stringValue), minute: Int(untilMinute.stringValue))
			if let dateUntil = Calendar.current.date(from: dateComponentsUntil) {
				tracking.date_end = dateUntil
			}

			self.tracking = tracking
		}

		guard let tracking = tracking else { return }

		if (tracking.job != nil) {
			tracking.exported = SyncStatus.pending.rawValue
		}

		CoreDataHelper.save(in: tracking.managedObjectContext)

		if (tracking.job != nil || tracking.activity?.nfc ?? false) {
			tracking.export()
		} else if let _ = tracking.id {
			tracking.deleteFromServer().done({ _ in
				tracking.id = nil
				tracking.exported = nil
				CoreDataHelper.save()
			}).catch({ error in
				tracking.exported = SyncStatus.error.rawValue
				CoreDataHelper.save()
			})
		}

		removeFromParent()
	}

}

extension EditorController: QuoJobSelectionsDelegate {

	func taskDidChanged() {
		taskHours.stringValue = ""
	}

	func hoursForTaskDidFetched(task: Task) {
		var calendar = Calendar.current
		calendar.locale = Locale(identifier: "de")
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .full
		formatter.zeroFormattingBehavior = .dropTrailing
		formatter.allowedUnits = [.hour, .minute]
		formatter.calendar = calendar

		let secondsPlanned = task.hours_planned * 3600
		let secondsBooked = task.hours_booked * 3600

		let planned = formatter.string(from: secondsPlanned)
		let booked = formatter.string(from: secondsBooked)

		let text = NSMutableAttributedString()
		text.append(NSAttributedString(string: "\(booked!)"))

		if (secondsPlanned > 0) {
			text.append(NSAttributedString(string: " von \(planned!) gebucht"))

			let percentage = round(secondsBooked / secondsPlanned * 1000) / 10
			var color = NSColor(ciColor: CIColor(red: 0, green: 0.649, blue: 0.079))

			if (percentage > 100) {
				color = NSColor(ciColor: CIColor(red: 0.846, green:0.032, blue: 0))
			} else if (percentage > 75) {
				color = NSColor(ciColor: CIColor(red: 0.846, green: 0.509, blue: 0))
			} else {
	//			hoursTaskLabel.backgroundColor = NSColor(ciColor: CIColor(red: 0, green: 0.649, blue: 0.079))
			}

			let seperator = NSAttributedString(string: " | ")

			let foo = NSAttributedString(
				string: "\(percentage)%",
				attributes: [
					NSAttributedString.Key.foregroundColor: color
				]
			)

			text.append(seperator)
			text.append(foo)
		} else {
			 text.append(NSAttributedString(string: " gebucht"))
		}

		taskHours.attributedStringValue = text
	}

}

extension EditorController: DateFieldDelegate {

	func getFromMonth() -> Int? {
		return Int(fromMonth!.stringValue)
	}

	func getFromYear() -> Int? {
		return Int(fromYear!.stringValue)
	}

}
