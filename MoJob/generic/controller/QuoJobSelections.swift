//
//  QuoJobSelections.swift
//  MoJob
//
//  Created by Martin Schneider on 06.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class QuoJobSelections: NSViewController {

	@IBOutlet weak var jobSelect: NSComboBox!
	@IBOutlet weak var taskSelect: NSComboBox!
	@IBOutlet weak var activitySelect: NSComboBox!
	@IBOutlet weak var fromDay: NumberField?
	@IBOutlet weak var fromMonth: NumberField?
	@IBOutlet weak var fromYear: NumberField?
	@IBOutlet weak var fromHour: NumberField!
	@IBOutlet weak var fromMinute: NumberField!
	@IBOutlet weak var untilHour: NumberField?
	@IBOutlet weak var untilMinute: NumberField?
	@IBOutlet weak var untilDay: NumberField?
	@IBOutlet weak var untilMonth: NumberField?
	@IBOutlet weak var untilYear: NumberField?
	@IBOutlet weak var comment: NSTextField!

	let userDefaults = UserDefaults()
	var tempTracking: TempTracking?
	var tracking: Tracking? = CoreDataHelper.shared.currentTracking
	var jobs: [Job] = []
	var tasks: [Task] = []
	var activities: [Activity] = []
	var startDate = Date()

	var formIsValid: Bool {
		get { return tempTracking?.isValid ?? false || tracking?.isValid ?? false }
		set { _ = newValue }
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		initJobSelect()
		initTaskSelect()
		initActivitySelect()
		initCommentText()
		initStartDate()
		initEndDate()
	}

	private func initJobSelect() {
		jobSelect.placeholderString = "Job wählen oder eingeben"

		if let jobs = QuoJob.shared.jobs {
			self.jobs = jobs
				.sorted(by: {
					$0.type!.id! != $1.type!.id! && $0.type!.title! < $1.type!.title! ||
						$0.number! != $1.number! && $0.number! < $1.number! ||
						$0.title! < $1.title!
				})
		}

		jobSelect.reloadData()

		if let job = tempTracking?.job ?? tracking?.job {
			if let index = jobs.index(where: { $0.id == job.id }) {
				jobSelect.selectItem(at: index)
			}
		} else if let customJob = tempTracking?.custom_job ?? tracking?.custom_job {
			jobSelect.stringValue = customJob
		}
	}

	private func initTaskSelect() {
		if let tasks = QuoJob.shared.tasks {
			self.tasks = tasks
				.filter({ $0.job!.id == tempTracking?.job?.id ?? tracking?.job?.id })
				.sorted(by: { $0.title! < $1.title! })
		}

		taskSelect.reloadData()

		if (tasks.count > 0) {
			taskSelect.placeholderString = "Aufgabe wählen oder eingeben"
			taskSelect.isEnabled = true
		} else {
			taskSelect.placeholderString = "keine Aufgaben verfügbar"
			taskSelect.isEnabled = false
		}

		if let task = tempTracking?.task ?? tracking?.task {
			if let index = tasks.index(where: { $0.id == task.id }) {
				taskSelect.selectItem(at: index)
			}
		}
	}

	private func initActivitySelect() {
		activitySelect.placeholderString = "Leistungsart wählen oder eingeben"

		if let activities = QuoJob.shared.activities {
			self.activities = activities
				.filter({
					if let job = tempTracking?.job ?? tracking?.job {
						return
							(job.type?.internal_service ?? true && $0.internal_service) ||
							(job.type?.productive_service ?? true && $0.external_service)
					}

					return $0.internal_service || $0.nfc
				})
				.sorted(by: { $0.title! < $1.title! })
		}

		activitySelect.reloadData()

		if let activity = tempTracking?.activity ?? tracking?.activity, let activityId = activity.id {
			if let index = activities.index(where: { $0.id == activityId }) {
				activitySelect.selectItem(at: index)
			}
		} else if let activityId = userDefaults.string(forKey: "activity") {
			if let activity = activities.first(where: { $0.id == activityId }), let index = activities.index(where: { $0 == activity }) {
				activitySelect.selectItem(at: index)
				tempTracking?.activity = activity
			}
		}
	}

	private func initCommentText() {
		comment.delegate = self
	}

	private func initStartDate() {
		guard let dateStart = tempTracking?.date_start ?? tracking?.date_start else { return }

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
		if let dateEnd = tempTracking?.date_end ?? tracking?.date_end {
			let day = Calendar.current.component(.day, from: dateEnd)
			untilDay?.stringValue = String(format: "%02d", day)
			let month = Calendar.current.component(.month, from: dateEnd)
			untilMonth?.stringValue = String(format: "%02d", month)
			let year = Calendar.current.component(.year, from: dateEnd)
			untilYear?.stringValue = String(year)

			let hour = Calendar.current.component(.hour, from: dateEnd)
			untilHour?.stringValue = String(format: "%02d", hour)
			let minute = Calendar.current.component(.minute, from: dateEnd)
			untilMinute?.stringValue = String(format: "%02d", minute)
		}
	}

	@IBAction func jobSelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			tempTracking?.job = nil
			tempTracking?.task = nil

			tracking?.update(with: ["job": nil, "task": nil]).catch { error in
				print(error)
			}
		} else if let job = QuoJob.shared.jobs?.first(where: { $0.fullTitle.lowercased() == value }) {
			tempTracking?.job = job

			tracking?.update(with: ["job": job]).catch { error in
				print(error)
			}
		} else {
			tempTracking?.job = nil
			tempTracking?.custom_job = value

			tracking?.update(with: ["job": nil, "custom_job": value]).catch { error in
				print(error)
			}
		}

		initTaskSelect()
		initActivitySelect()

		formIsValid = true
	}

	@IBAction func taskSelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			tempTracking?.task = nil
			tracking?.update(with: ["task": nil]).catch({ _ in })
		} else if let task = QuoJob.shared.tasks?.first(where: { $0.title?.lowercased() == value }) {
			tempTracking?.task = task
			tracking?.update(with: ["task": task]).catch({ _ in })
		}
	}

	@IBAction func activitySelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			jobSelect.isEnabled = true
			tempTracking?.activity = nil
			tracking?.update(with: ["activity": nil]).catch({ _ in })
			formIsValid = false
		} else if let activity = QuoJob.shared.activities?
			.filter({
				if let job = tempTracking?.job ?? tracking?.job {
					return (job.type?.internal_service ?? true && $0.internal_service) || (job.type?.productive_service ?? true && $0.external_service)
				}

				return $0.internal_service || $0.nfc
			})
			.first(where: { $0.title?.lowercased() == value })
		{
			if (activity.nfc) {
				jobSelect.cell?.stringValue = ""
				tempTracking?.job = nil
				tracking?.update(with: ["job": nil]).catch({ _ in })
				jobSelect.isEnabled = false
			} else {
				jobSelect.isEnabled = true
			}

			tempTracking?.activity = activity
			tracking?.update(with: ["activity": activity]).catch({ _ in })
			formIsValid = true
		}
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
		if let dateStart = tempTracking?.date_start ?? tracking?.date_start, [fromMinute, fromHour, fromDay, fromMonth, fromYear].contains(textField), textField.stringValue != "" {
			var comp = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dateStart)

			if let fromYear = fromYear {
				comp.year = fromYear.stringValue != "" ? Int(fromYear.stringValue) : comp.year
			}

			if let fromMonth = fromMonth {
				comp.month = fromMonth.stringValue != "" ? Int(fromMonth.stringValue) : comp.month
			}

			if let fromDay = fromDay {
				comp.day = fromDay.stringValue != "" ? Int(fromDay.stringValue) : comp.day
			}

			comp.hour = fromHour.stringValue != "" ? Int(fromHour.stringValue) : comp.hour
			comp.minute = fromMinute.stringValue != "" ? Int(fromMinute.stringValue) : comp.minute

			if let newStartDate = Calendar.current.date(from: comp) {
				tempTracking?.date_start = newStartDate
				tracking?.update(with: ["date_start": newStartDate]).catch({ _ in })
				startDate = newStartDate
				formIsValid = true
			}
		}

		if let dateEnd = tempTracking?.date_end, [untilMinute, untilHour, untilDay, untilMonth, untilYear].contains(textField) {
			var comp = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dateEnd)
			comp.year = untilYear?.stringValue != "" ? Int(untilYear?.stringValue ?? Date().year) : comp.year
			comp.month = untilMonth?.stringValue != "" ? Int(untilMonth?.stringValue ?? Date().month) : comp.month
			comp.day = untilDay?.stringValue != "" ? Int(untilDay?.stringValue ?? Date().day) : comp.day
			comp.hour = untilHour?.stringValue != "" ? Int(untilHour?.stringValue ?? "23") : comp.hour
			comp.minute = untilMinute?.stringValue != "" ? Int(untilMinute?.stringValue ?? "59") : comp.minute

			if let newEndDate = Calendar.current.date(from: comp) {
				tempTracking?.date_end = newEndDate
				formIsValid = true
			}
		}

		if (textField == comment) {
			tempTracking?.comment = textField.stringValue
			tracking?.update(with: ["comment": textField.stringValue]).catch({ _ in })
		}
	}

	private func handleTextChange(in comboBox: NSComboBox) {
		guard let comboBoxCell = comboBox.cell as? NSComboBoxCell else { return }
		let value = comboBoxCell.stringValue.lowercased()

		if (comboBox.isEqual(jobSelect)) {
			jobs = QuoJob.shared.jobs!
				.filter({ value == "" || $0.fullTitle.lowercased().contains(value) })
				.sorted(by: {
					$0.type!.id! != $1.type!.id! && $0.type!.title! < $1.type!.title! ||
						$0.number! != $1.number! && $0.number! < $1.number! ||
						$0.title! < $1.title!
				})

			if (jobs.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			}
		} else if (comboBox.isEqual(taskSelect)) {
			tasks = QuoJob.shared.tasks!
				.filter({ value == "" || $0.job!.id == tempTracking?.job?.id ?? tracking?.job?.id && $0.title!.lowercased().contains(value) })
				.sorted(by: { $0.title! < $1.title! })

			if (tasks.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			}
		} else if (comboBox.isEqual(activitySelect)) {
			activities = QuoJob.shared.activities!
				.filter({
					if let job = tempTracking?.job ?? tracking?.job {
						return (job.type?.internal_service ?? true && $0.internal_service) || (job.type?.productive_service ?? true && $0.external_service)
					}

					return $0.internal_service || $0.nfc
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