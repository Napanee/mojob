//
//  QuoJobSelections.swift
//  MoJob
//
//  Created by Martin Schneider on 06.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa
import PromiseKit

protocol QuoJobSelectionsDelegate {
	func hoursForTaskDidFetched(task: Task)
	func jobDidChanged()
	func taskDidChanged()
	func activityDidChanged()
}

extension QuoJobSelectionsDelegate {
	func jobDidChanged() {}
	func taskDidChanged() {}
	func activityDidChanged() {}
}

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
	@IBOutlet weak var comment: TextField!

	let userDefaults = UserDefaults()
	var delegate: QuoJobSelectionsDelegate?
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
		var selectedJob: Job?
		var selectedJobIndex = jobSelect.indexOfSelectedItem
		let selectedJobValue = jobSelect.stringValue.lowercased()

		if (selectedJobIndex < 0 && selectedJobValue != "") {
			selectedJobIndex = jobs.firstIndex(where: { $0.fullTitle.lowercased() == selectedJobValue }) ?? -1
		}
		
		if (selectedJobIndex >= 0 && jobs.count > selectedJobIndex) {
			selectedJob = jobs[selectedJobIndex]
		}

		tasks = CoreDataHelper.tasks(in: tracking?.managedObjectContext)
			.filter({
				if let id = $0.job?.id, let job = tracking?.job ?? selectedJob {
					return id == job.id
				}
				
				return false
			})
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

			if let id = task.id, Date().timeIntervalSince(task.sync!) > Double(userDefaults.integer(forKey: UserDefaults.Keys.taskHoursInterval) * 60) {
				firstly(execute: {
					return QuoJob.shared.login()
				}).then({ success in
					return QuoJob.shared.fetchTasks(with: [id])
				}).then({ resultTasks in
					return QuoJob.shared.handleTasks(with: resultTasks, updateTimestamp: false)
				}).done({ _ in
					CoreDataHelper.save()
				}).catch({ _ in
				}).finally({
					self.delegate?.hoursForTaskDidFetched(task: task)
				})
			} else {
				delegate?.hoursForTaskDidFetched(task: task)
			}
		}
	}

	private func initActivitySelect() {
		activitySelect.placeholderString = "Leistungsart wählen oder eingeben"
		
		var selectedJob: Job?
		var selectedJobIndex = jobSelect.indexOfSelectedItem
		let selectedJobValue = jobSelect.stringValue.lowercased()

		if (selectedJobIndex < 0 && selectedJobValue != "") {
			selectedJobIndex = jobs.firstIndex(where: { $0.fullTitle.lowercased() == selectedJobValue }) ?? -1
		}
		
		if (selectedJobIndex >= 0 && jobs.count > selectedJobIndex) {
			selectedJob = jobs[selectedJobIndex]
		}

		activities = CoreDataHelper.activities(in: tracking?.managedObjectContext)
			.filter({
				if let job = tracking?.job ?? selectedJob {
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
		comment?.delegate = self

		guard let commentText = tracking?.comment else {
			comment?.stringValue = ""
			return
		}

		comment?.stringValue = commentText
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

extension QuoJobSelections: NSComboBoxDelegate {

	func comboBoxWillDismiss(_ notification: Notification) {
		guard let comboBox = notification.object as? NSComboBox else { return }

		if (comboBox.isEqual(jobSelect)) {
			handleJobChange(comboBox: comboBox)
			formIsValid = true
		} else if (comboBox.isEqual(taskSelect)) {
			handleTaskChange(comboBox: comboBox)
			formIsValid = true
		} else if (comboBox.isEqual(activitySelect)) {
			handleActivityChange(comboBox: comboBox)
			formIsValid = true
		}
	}

	private func handleJobChange(comboBox: NSComboBox) {
		delegate?.jobDidChanged()

		if let tracking = tracking {
			var index = comboBox.indexOfSelectedItem
			let value = comboBox.stringValue.lowercased()

			tracking.task = nil

			if (index < 0 && value != "") {
				index = jobs.firstIndex(where: { $0.fullTitle.lowercased() == value }) ?? -1
			}

			if (index >= 0) {
				tracking.job = jobs[index]
				tracking.custom_job = nil
			} else if (value == "") {
				tracking.job = nil
				tracking.custom_job = nil
			} else {
				tracking.job = nil
				tracking.custom_job = value
			}
		}
		
		delegate?.taskDidChanged()
		taskSelect.deselectItem(at: taskSelect.indexOfSelectedItem)
		taskSelect.stringValue = ""
		initTaskSelect()
		initActivitySelect()
	}

	private func handleTaskChange(comboBox: NSComboBox) {
		delegate?.taskDidChanged()

		let index = comboBox.indexOfSelectedItem

		if (index < 0) {
			tracking?.task = nil
			return
		}

		let task = tasks[index]

		if let delegate = delegate {
			if let id = task.id, Date().timeIntervalSince(task.sync!) > Double(userDefaults.integer(forKey: UserDefaults.Keys.taskHoursInterval) * 60) {
				firstly(execute: {
					return QuoJob.shared.login()
				}).then({ success in
					return QuoJob.shared.fetchTasks(with: [id])
				}).then({ resultTasks in
					return QuoJob.shared.handleTasks(with: resultTasks, updateTimestamp: false)
				}).done({ _ in
					CoreDataHelper.save()
				}).catch({ _ in
				}).finally({
					delegate.hoursForTaskDidFetched(task: task)
				})
			} else {
				delegate.hoursForTaskDidFetched(task: task)
			}
		}

		if let tracking = tracking {
			tracking.task = task
		}
	}

	private func handleActivityChange(comboBox: NSComboBox) {
		delegate?.activityDidChanged()

		let index = comboBox.indexOfSelectedItem

		if (index < 0) {
			tracking?.activity = nil
			jobSelect.isEnabled = true

			return
		}

		let activity = activities[index]

		tracking?.activity = activity

		if (nfc && activity.nfc) {
			tracking?.job = nil
			jobSelect.stringValue = ""
			jobSelect.deselectItem(at: jobSelect.indexOfSelectedItem)
			jobSelect.isEnabled = false
			delegate?.jobDidChanged()

			tracking?.task = nil
			taskSelect.stringValue = ""
			taskSelect.deselectItem(at: taskSelect.indexOfSelectedItem)
			taskSelect.isEnabled = false
			delegate?.taskDidChanged()
			initTaskSelect()
		} else {
			jobSelect.isEnabled = true
		}
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
			delegate?.jobDidChanged()

			jobs = CoreDataHelper.jobs(in: tracking?.managedObjectContext)
				.filter({ value == "" || $0.fullTitle.lowercased().contains(value) })
				.sorted(by: { $0.number! != $1.number! ? $0.number! < $1.number! : $0.title! < $1.title! })


			if (jobs.count == 1 && jobs[0].title?.lowercased() == value.lowercased()) {
				comboBox.selectItem(at: 0)
			}

			formIsValid = true

			if (jobs.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			} else {
				comboBox.reloadData()
			}
		} else if (comboBox.isEqual(taskSelect)) {
			delegate?.taskDidChanged()

			let index = jobSelect.indexOfSelectedItem

			tasks = CoreDataHelper.tasks(in: tracking?.managedObjectContext)
				.filter({ $0.job?.id != nil && ($0.job?.id == tracking?.job?.id || index >= 0 && $0.job?.id == jobs[index].id) && (value == "" || ($0.title ?? "").lowercased().contains(value)) })
				.sorted(by: { $0.title! < $1.title! })

			if (tasks.count == 1 && tasks[0].title?.lowercased() == value.lowercased()) {
				comboBox.selectItem(at: 0)
			}

			formIsValid = true

			if (tasks.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			} else {
				comboBox.reloadData()
			}
		} else if (comboBox.isEqual(activitySelect)) {
			delegate?.activityDidChanged()

			activities = CoreDataHelper.activities(in: tracking?.managedObjectContext)
				.filter({
					if let job = tracking?.job {
						return (job.type?.internal_service ?? true && $0.internal_service) || (job.type?.productive_service ?? true && $0.external_service)
					}

					return $0.internal_service || (nfc ? $0.nfc : false)
				})
				.filter({ value == "" || $0.title!.lowercased().contains(value) })
				.sorted(by: { $0.title! < $1.title! })

			if (activities.count == 1 && activities[0].title?.lowercased() == value.lowercased()) {
				comboBox.selectItem(at: 0)
			}

			formIsValid = true

			if (activities.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			} else {
				comboBox.reloadData()
			}
		}
	}
}
