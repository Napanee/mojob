//
//  QuoJobSelections.swift
//  MoJob
//
//  Created by Martin Schneider on 06.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class QuoJobSelections: NSViewController {

	@IBOutlet weak var jobSelect: ComboBox!
	@IBOutlet weak var taskSelect: ComboBox!
	@IBOutlet weak var activitySelect: ComboBox!
	@IBOutlet weak var fromDay: NumberField!
	@IBOutlet weak var fromMonth: NumberField!
	@IBOutlet weak var fromYear: NumberField!
	@IBOutlet weak var fromHour: NumberField!
	@IBOutlet weak var fromMinute: NumberField!
	@IBOutlet weak var untilHour: NumberField!
	@IBOutlet weak var untilMinute: NumberField!
	@IBOutlet weak var comment: NSTextField!

	let userDefaults = UserDefaults()
	var dateStart: Date? {
		didSet {
			initStartDate()
		}
	}
	var dateEnd: Date? {
		didSet {
			initEndDate()
		}
	}
	var tracking: Tracking? {
		didSet {
			initEditor()
		}
	}
	var jobs: [Job] = []
	var tasks: [Task] = []
	var activities: [Activity] = []
	var nfc: Bool = true

	var formIsValid: Bool {
		get { return tracking?.isValid ?? false }
		set { _ = newValue }
	}

	func initEditor() {
		initJobSelect()
		initTaskSelect()
		initActivitySelect()
		initCommentText()
		initStartDate()
		initEndDate()
	}

	private func initJobSelect() {
		jobSelect.placeholderString = "Job wählen oder eingeben"

		jobs = CoreDataHelper.jobs(in: tracking?.managedObjectContext)
			.sorted(by: { $0.number! != $1.number! ? $0.number! < $1.number! : $0.title! < $1.title! })

		jobSelect.reloadData()

		if let job = tracking?.job {
			if let index = jobs.firstIndex(where: { $0.id == job.id }) {
				jobSelect.selectItem(at: index)
			}
		} else if let customJob = tracking?.custom_job {
			jobSelect.stringValue = customJob
		} else if (jobSelect.indexOfSelectedItem >= 0) {
			jobSelect.deselectItem(at: jobSelect.indexOfSelectedItem)
		}
	}

	private func initTaskSelect() {
		let index = jobSelect.indexOfSelectedItem

		tasks = CoreDataHelper.tasks(in: tracking?.managedObjectContext)
			.filter({ $0.job?.id == tracking?.job?.id || index >= 0 && $0.job?.id == jobs[index].id })
			.sorted(by: { $0.title! < $1.title! })

		taskSelect.reloadData()

		if (tasks.count > 0) {
			taskSelect.placeholderString = "Aufgabe wählen oder eingeben"
			taskSelect.isEnabled = true
		} else {
			taskSelect.placeholderString = "keine Aufgaben verfügbar"
			taskSelect.isEnabled = false
		}

		if let task = tracking?.task {
			if let index = tasks.firstIndex(where: { $0.id == task.id }) {
				taskSelect.selectItem(at: index)
			}
		}
	}

	private func initActivitySelect() {
		activitySelect.placeholderString = "Leistungsart wählen oder eingeben"

		activities = CoreDataHelper.activities(in: tracking?.managedObjectContext)
			.filter({
				if let job = tracking?.job {
					return
						(job.type?.internal_service ?? true && $0.internal_service) ||
						(job.type?.productive_service ?? true && $0.external_service)
				}

				return $0.internal_service || (nfc ? $0.nfc : false)
			})
			.sorted(by: { $0.title! < $1.title! })

		activitySelect.reloadData()

		if let activity = tracking?.activity, let activityId = activity.id {
			if let index = activities.firstIndex(where: { $0.id == activityId }) {
				activitySelect.selectItem(at: index)
			}
		} else if let activityId = userDefaults.string(forKey: UserDefaults.Keys.activity) {
			if let activity = activities.first(where: { $0.id == activityId }), let index = activities.firstIndex(where: { $0 == activity }) {
				activitySelect.selectItem(at: index)
				tracking?.activity = activity
			}
		} else if (activitySelect.indexOfSelectedItem >= 0) {
			activitySelect.deselectItem(at: activitySelect.indexOfSelectedItem)
		}
	}

	func initCommentText() {
		comment.delegate = self

		guard let commentText = tracking?.comment else {
			comment.stringValue = ""
			return
		}

		comment.stringValue = commentText
	}

	func initStartDate() {
		guard let dateStart: Date = tracking?.date_start ?? self.dateStart else { return }

		let day = Calendar.current.component(.day, from: dateStart)
		fromDay?.stringValue = String(format: "%02d", day)
		let month = Calendar.current.component(.month, from: dateStart)
		fromMonth?.stringValue = String(format: "%02d", month)
		let year = Calendar.current.component(.year, from: dateStart)
		fromYear?.stringValue = String(year)

		let hour = Calendar.current.component(.hour, from: dateStart)
		fromHour.stringValue = String(format: "%02d", hour)
		let minute = Calendar.current.component(.minute, from: dateStart)
		fromMinute.stringValue = String(format: "%02d", minute)
	}

	private func initEndDate() {
		guard let dateEnd: Date = tracking?.date_end ?? self.dateEnd else { return }

		let hour = Calendar.current.component(.hour, from: dateEnd)
		untilHour?.stringValue = String(format: "%02d", hour)
		let minute = Calendar.current.component(.minute, from: dateEnd)
		untilMinute?.stringValue = String(format: "%02d", minute)

		if let dateStart = tracking?.date_start ?? self.dateStart {
			var comp = Calendar.current.dateComponents([.year, .month, .day], from: dateStart)
			comp.hour = hour
			comp.minute = minute

			if let newEndDate = Calendar.current.date(from: comp) {
				tracking?.date_end = newEndDate
			}
		}
	}

	@IBAction func jobSelect(_ sender: NSComboBox) {
		if let cell = sender.cell, let tracking = tracking, let context = tracking.managedObjectContext {
			let value = cell.stringValue.lowercased()

			if (value == "") {
				tracking.job = nil
				tracking.task = nil
			} else if let job = CoreDataHelper.jobs(in: context).first(where: { $0.fullTitle.lowercased() == value }) {
				tracking.job = job
				tracking.custom_job = nil
			} else {
				tracking.job = nil
				tracking.custom_job = value
			}
		}

		taskSelect.stringValue = ""
		initTaskSelect()
		initActivitySelect()

		formIsValid = true
	}

	@IBAction func taskSelect(_ sender: NSComboBox) {
		guard let cell = sender.cell, let tracking = tracking, let context = tracking.managedObjectContext else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			tracking.task = nil
		} else if let task = CoreDataHelper.tasks(in: context).first(where: { $0.title?.lowercased() == value }) {
			tracking.task = task
		}
	}

	@IBAction func activitySelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()
		let activity = CoreDataHelper.activities(in: tracking?.managedObjectContext)
			.filter({
				if let job = tracking?.job {
					return (job.type?.internal_service ?? true && $0.internal_service) || (job.type?.productive_service ?? true && $0.external_service)
				}

				return $0.internal_service || (nfc && $0.nfc)
			})
			.first(where: { $0.title?.lowercased() == value })

		if let tracking = tracking, let _ = tracking.managedObjectContext {
			if (value == "") {
				tracking.activity = nil
			} else if let activity = activity {
				if (nfc && activity.nfc) {
					tracking.job = nil
				}

				tracking.activity = activity
			}
		}

		if (value == "") {
			jobSelect.isEnabled = true
			taskSelect.isEnabled = true
		} else if let activity = activity {
			if (nfc && activity.nfc) {
				jobSelect.cell?.stringValue = ""
				jobSelect.deselectItem(at: jobSelect.indexOfSelectedItem)
				jobSelect.isEnabled = false
				taskSelect.cell?.stringValue = ""
				taskSelect.deselectItem(at: taskSelect.indexOfSelectedItem)
				taskSelect.isEnabled = false
			} else {
				jobSelect.isEnabled = true
				taskSelect.isEnabled = true
			}
		}

		initTaskSelect()

		formIsValid = true
	}

}

extension QuoJobSelections: NSComboBoxDataSource {

	func numberOfItems(in comboBox: NSComboBox) -> Int {
		if (comboBox.isEqual(jobSelect)) {
			return jobs.count
		} else if (comboBox.isEqual(taskSelect)) {
			return tasks.count
		} else if (comboBox.isEqual(activitySelect)) {
			return activities.count
		}

		return 0
	}

	func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
		if (comboBox.isEqual(jobSelect)) {
			let job = jobs[index]
			return job.fullTitle
		} else if (comboBox.isEqual(taskSelect)) {
			return tasks[index].title
		} else if (comboBox.isEqual(activitySelect)) {
			return activities[index].title
		}

		return ""
	}

}

extension QuoJobSelections: NSTextFieldDelegate {
	func controlTextDidChange(_ obj: Notification) {
		if let textField = obj.object as? NSTextField {
			handleTextChange(in: textField)
		}

		if let comboBox = obj.object as? NSComboBox {
			handleTextChange(in: comboBox)
		}
	}

	private func handleTextChange(in textField: NSTextField) {
		if let dateStart = tracking?.date_start, [fromMinute, fromHour, fromDay, fromMonth, fromYear].contains(textField), textField.stringValue != "" {
			var compStart = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: dateStart)

			if let fromYear = fromYear {
				compStart.year = fromYear.stringValue != "" ? Int(fromYear.stringValue) : compStart.year
			}

			if let fromMonth = fromMonth {
				compStart.month = fromMonth.stringValue != "" ? Int(fromMonth.stringValue) : compStart.month
			}

			if let fromDay = fromDay {
				compStart.day = fromDay.stringValue != "" ? Int(fromDay.stringValue) : compStart.day
			}

			compStart.hour = fromHour.stringValue != "" ? Int(fromHour.stringValue) : compStart.hour
			compStart.minute = fromMinute.stringValue != "" ? Int(fromMinute.stringValue) : compStart.minute

			if let newStartDate = Calendar.current.date(from: compStart) {
				if let dateEnd = tracking?.date_end {
					var compEnd = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dateEnd)
					compEnd.year = compStart.year
					compEnd.month = compStart.month
					compEnd.day = compStart.day

					if let newEndDate = Calendar.current.date(from: compEnd) {
						tracking?.date_end = newEndDate
					}
				}

				tracking?.date_start = newStartDate
				formIsValid = true
			}
		}

		if let dateEnd = tracking?.date_end, [untilMinute, untilHour].contains(textField) {
			var comp = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dateEnd)
			comp.hour = untilHour?.stringValue != "" ? Int(untilHour?.stringValue ?? "23") : comp.hour
			comp.minute = untilMinute?.stringValue != "" ? Int(untilMinute?.stringValue ?? "59") : comp.minute

			if let newEndDate = Calendar.current.date(from: comp) {
				tracking?.date_end = newEndDate
				formIsValid = true
			}
		}

		if (textField == comment) {
			tracking?.comment = textField.stringValue
		}
	}

	private func handleTextChange(in comboBox: NSComboBox) {
		guard let comboBoxCell = comboBox.cell as? NSComboBoxCell else { return }
		let value = comboBoxCell.stringValue.lowercased()

		if (comboBox.isEqual(jobSelect)) {
			jobs = CoreDataHelper.jobs(in: tracking?.managedObjectContext)
				.filter({ value == "" || $0.fullTitle.lowercased().contains(value) })
				.sorted(by: { $0.number! != $1.number! ? $0.number! < $1.number! : $0.title! < $1.title! })

			if (jobs.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			}
		} else if (comboBox.isEqual(taskSelect)) {
			let index = jobSelect.indexOfSelectedItem

			tasks = CoreDataHelper.tasks(in: tracking?.managedObjectContext)
				.filter({ ($0.job?.id == tracking?.job?.id || index >= 0 && $0.job?.id == jobs[index].id) && (value == "" || ($0.title ?? "").lowercased().contains(value)) })
				.sorted(by: { $0.title! < $1.title! })

			if (tasks.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			}
		} else if (comboBox.isEqual(activitySelect)) {
			activities = CoreDataHelper.activities(in: tracking?.managedObjectContext)
				.filter({
					if let job = tracking?.job {
						return (job.type?.internal_service ?? true && $0.internal_service) || (job.type?.productive_service ?? true && $0.external_service)
					}

					return $0.internal_service || (nfc ? $0.nfc : false)
				})
				.filter({ value == "" || $0.title!.lowercased().contains(value) })
				.sorted(by: { $0.title! < $1.title! })

			if (activities.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			}
		}

		comboBox.reloadData()
	}
}
