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
	@IBOutlet weak var comment: NSTextField!

	let userDefaults = UserDefaults()
	var tempTracking: TempTracking? {
		didSet {
			if let _ = tempTracking {
				tracking = nil
			}
		}
	}
	var tracking: Tracking? = CoreDataHelper.shared.currentTracking
	var jobs: [Job] = []
	var tasks: [Task] = []
	var activities: [Activity] = []
	var startDate = Date()
	var nfc: Bool = true

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

		self.jobs = QuoJob.shared.jobs
			.sorted(by: { $0.number! != $1.number! ? $0.number! < $1.number! : $0.title! < $1.title! })

		jobSelect.reloadData()

		if let job = tempTracking?.job ?? tracking?.job {
			if let index = jobs.firstIndex(where: { $0.id == job.id }) {
				jobSelect.selectItem(at: index)
			}
		} else if let customJob = tempTracking?.custom_job ?? tracking?.custom_job {
			jobSelect.stringValue = customJob
		}
	}

	private func initTaskSelect() {
		self.tasks = QuoJob.shared.tasks
			.filter({ $0.job?.id == tempTracking?.job?.id ?? tracking?.job?.id })
			.sorted(by: { $0.title! < $1.title! })

		taskSelect.reloadData()

		if (tasks.count > 0) {
			taskSelect.placeholderString = "Aufgabe wählen oder eingeben"
			taskSelect.isEnabled = true
		} else {
			taskSelect.placeholderString = "keine Aufgaben verfügbar"
			taskSelect.isEnabled = false
		}

		if let task = tempTracking?.task ?? tracking?.task {
			if let index = tasks.firstIndex(where: { $0.id == task.id }) {
				taskSelect.selectItem(at: index)
			}
		}
	}

	private func initActivitySelect() {
		activitySelect.placeholderString = "Leistungsart wählen oder eingeben"

		self.activities = QuoJob.shared.activities
			.filter({
				if let job = tempTracking?.job ?? tracking?.job {
					return
						(job.type?.internal_service ?? true && $0.internal_service) ||
						(job.type?.productive_service ?? true && $0.external_service)
				}

				return $0.internal_service || (nfc ? $0.nfc : false)
			})
			.sorted(by: { $0.title! < $1.title! })

		activitySelect.reloadData()

		if let activity = tempTracking?.activity ?? tracking?.activity, let activityId = activity.id {
			if let index = activities.firstIndex(where: { $0.id == activityId }) {
				activitySelect.selectItem(at: index)
			}
		} else if let activityId = userDefaults.string(forKey: UserDefaults.Keys.activity) {
			if let activity = activities.first(where: { $0.id == activityId }), let index = activities.firstIndex(where: { $0 == activity }) {
				activitySelect.selectItem(at: index)
				tempTracking?.activity = activity
				tracking?.activity = activity
			}
		}
	}

	func initCommentText() {
		comment.delegate = self

		guard let commentText = tempTracking?.comment ?? tracking?.comment else { return }
		comment.stringValue = commentText
	}

	func initStartDate() {
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

			tracking?.update(with: ["job": nil, "task": nil]).done({ _ in }).catch({ _ in })
		} else if let job = QuoJob.shared.jobs.first(where: { $0.fullTitle.lowercased() == value }) {
			tempTracking?.job = job
			tempTracking?.custom_job = nil

			tracking?.update(with: ["job": job, "custom_job": nil]).done({ _ in }).catch({ _ in })
		} else {
			tempTracking?.job = nil
			tempTracking?.custom_job = value

			tracking?.update(with: ["job": nil, "custom_job": value]).done({ _ in }).catch({ _ in })
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
			tracking?.update(with: ["task": nil]).done({ _ in }).catch({ _ in })
		} else if let task = QuoJob.shared.tasks.first(where: { $0.title?.lowercased() == value }) {
			tempTracking?.task = task
			tracking?.update(with: ["task": task]).done({ _ in }).catch({ _ in })
		}
	}

	@IBAction func activitySelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			jobSelect.isEnabled = true
			tempTracking?.activity = nil
			tracking?.update(with: ["activity": nil]).done({ _ in }).catch({ _ in })
		} else if let activity = QuoJob.shared.activities
			.filter({
				if let job = tempTracking?.job ?? tracking?.job {
					return (job.type?.internal_service ?? true && $0.internal_service) || (job.type?.productive_service ?? true && $0.external_service)
				}

				return $0.internal_service || (nfc ? $0.nfc : false)
			})
			.first(where: { $0.title?.lowercased() == value })
		{
			if (nfc && activity.nfc) {
				jobSelect.cell?.stringValue = ""
				tempTracking?.job = nil
				tracking?.update(with: ["job": nil]).done({ _ in }).catch({ _ in })
				jobSelect.isEnabled = false
			} else {
				jobSelect.isEnabled = true
			}

			tempTracking?.activity = activity
			tracking?.update(with: ["activity": activity]).done({ _ in }).catch({ _ in })
		}

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
		if let dateStart = tempTracking?.date_start ?? tracking?.date_start, [fromMinute, fromHour, fromDay, fromMonth, fromYear].contains(textField), textField.stringValue != "" {
			var compStart = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dateStart)

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
				if let dateEnd = tempTracking?.date_end ?? tracking?.date_end {
					var compEnd = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dateEnd)

					if let newEndDate = Calendar.current.date(from: compEnd) {
						compEnd.year = compStart.year
						compEnd.month = compStart.month
						compEnd.day = compStart.day

						tempTracking?.date_end = newEndDate
					}
				}

				tempTracking?.date_start = newStartDate
				tracking?.update(with: ["date_start": newStartDate]).done({ _ in }).catch({ _ in })
				startDate = newStartDate
				formIsValid = true
			}
		}

		if let dateEnd = tempTracking?.date_end, [untilMinute, untilHour].contains(textField) {
			var comp = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dateEnd)
			comp.hour = untilHour?.stringValue != "" ? Int(untilHour?.stringValue ?? "23") : comp.hour
			comp.minute = untilMinute?.stringValue != "" ? Int(untilMinute?.stringValue ?? "59") : comp.minute

			if let newEndDate = Calendar.current.date(from: comp) {
				tempTracking?.date_end = newEndDate
				formIsValid = true
			}
		}

		if (textField == comment) {
			tempTracking?.comment = textField.stringValue
			tracking?.update(with: ["comment": textField.stringValue]).done({ _ in }).catch({ _ in })
		}
	}

	private func handleTextChange(in comboBox: NSComboBox) {
		guard let comboBoxCell = comboBox.cell as? NSComboBoxCell else { return }
		let value = comboBoxCell.stringValue.lowercased()

		if (comboBox.isEqual(jobSelect)) {
			jobs = QuoJob.shared.jobs
				.filter({ $0.fullTitle.lowercased().contains(value) })
				.sorted(by: { $0.number! != $1.number! ? $0.number! < $1.number! : $0.title! < $1.title! })

			if (jobs.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			}
		} else if (comboBox.isEqual(taskSelect)) {
			tasks = QuoJob.shared.tasks
				.filter({ $0.job?.id == tempTracking?.job?.id ?? tracking?.job?.id && ($0.title ?? "").lowercased().contains(value) })
				.sorted(by: { $0.title! < $1.title! })

			if (tasks.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			}
		} else if (comboBox.isEqual(activitySelect)) {
			activities = QuoJob.shared.activities
				.filter({
					if let job = tempTracking?.job ?? tracking?.job {
						return (job.type?.internal_service ?? true && $0.internal_service) || (job.type?.productive_service ?? true && $0.external_service)
					}

					return $0.internal_service || (nfc ? $0.nfc : false)
				})
				.filter({ $0.title!.lowercased().contains(value) })
				.sorted(by: { $0.title! < $1.title! })

			if (activities.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			}
		}

		comboBox.reloadData()
	}
}
