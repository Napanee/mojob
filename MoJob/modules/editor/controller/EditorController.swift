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
				return jobSelect.stringValue.count > 0 || activity.nfc
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

	override func viewDidLoad() {
		super.viewDidLoad()

		initEditor()

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
			let tracking = CoreDataHelper.createTracking()

			if let job = CoreDataHelper.jobs().first(where: { $0.fullTitle.lowercased() == jobSelect.stringValue.lowercased() }) {
				tracking?.job = job
			} else if (jobSelect.stringValue != "") {
				tracking?.custom_job = jobSelect.stringValue
			}

			if let activity = CoreDataHelper.activities().first(where: { $0.title?.lowercased() == activitySelect.stringValue.lowercased() }) {
				tracking?.activity = activity
			}

			if let task = CoreDataHelper.tasks().first(where: { $0.title?.lowercased() == taskSelect.stringValue.lowercased() }) {
				tracking?.task = task
			}

			tracking?.comment = comment.stringValue.count > 0 ? comment.stringValue : nil

			let dateComponentsStart = DateComponents(year: Int(fromYear.stringValue), month: Int(fromMonth.stringValue), day: Int(fromDay.stringValue), hour: Int(fromHour.stringValue), minute: Int(fromMinute.stringValue))
			if let dateStart = Calendar.current.date(from: dateComponentsStart) {
				tracking?.date_start = dateStart
			}

			let dateComponentsUntil = DateComponents(year: Int(fromYear.stringValue), month: Int(fromMonth.stringValue), day: Int(fromDay.stringValue), hour: Int(untilHour.stringValue), minute: Int(untilMinute.stringValue))
			if let dateUntil = Calendar.current.date(from: dateComponentsUntil) {
				tracking?.date_end = dateUntil
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

extension EditorController: DateFieldDelegate {

	func getFromMonth() -> Int? {
		return Int(fromMonth!.stringValue)
	}

	func getFromYear() -> Int? {
		return Int(fromYear!.stringValue)
	}

}
