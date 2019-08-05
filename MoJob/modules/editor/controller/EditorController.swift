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
	func getUntilMonth() -> Int?
	func getUntilYear() -> Int?
}

class EditorController: NSViewController {
	var tracking: Tracking? {
		didSet {
			if let tracking = tracking {
				self.tempTracking = TempTracking(tracking: tracking)
			}
		}
	}
	var tempTracking: TempTracking!
	var formIsValid: Bool {
		get {
			if (
				tempTracking.activity != nil &&
				(tempTracking.date_end ?? Date()).timeIntervalSince(tempTracking.date_start) > 60 &&
				(tempTracking.job != nil || tempTracking.custom_job != nil || tempTracking.activity!.nfc)
			) {
				return true
			}

			return false
		}
	}
	var userDefaults = UserDefaults()
	var jobs: [Job] = []
	var tasks: [Task] = []
	var activities: [Activity] = []

	let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext

	@IBOutlet weak var fromDay: NumberField!
	@IBOutlet weak var fromMonth: NumberField!
	@IBOutlet weak var fromYear: NumberField!
	@IBOutlet weak var fromHour: NumberField!
	@IBOutlet weak var fromMinute: NumberField!
	@IBOutlet weak var untilHour: NumberField!
	@IBOutlet weak var untilMinute: NumberField!
	@IBOutlet weak var untilDay: NumberField!
	@IBOutlet weak var untilMonth: NumberField!
	@IBOutlet weak var untilYear: NumberField!
	@IBOutlet weak var comment: NSTextField!
	@IBOutlet weak var jobSelect: NSComboBox!
	@IBOutlet weak var taskSelect: NSComboBox!
	@IBOutlet weak var activitySelect: NSComboBox!
	@IBOutlet weak var saveButton: NSButton!
	@IBOutlet weak var deleteButton: NSButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		fromDay.dateDelegate = self
		untilDay.dateDelegate = self
		comment.delegate = self

		saveButton.isEnabled = formIsValid
		deleteButton.isHidden = tracking == nil

		initJobSelect()
		initTaskSelect()
		initActivitySelect()

		if let commentString = tempTracking.comment {
			comment.stringValue = commentString
		}

		let dateStart = tempTracking.date_start
		let day = Calendar.current.component(.day, from: dateStart)
		fromDay.stringValue = String(format: "%02d", day)
		let month = Calendar.current.component(.month, from: dateStart)
		fromMonth.stringValue = String(format: "%02d", month)
		let year = Calendar.current.component(.year, from: dateStart)
		fromYear.stringValue = String(year)

		let hour = Calendar.current.component(.hour, from: dateStart)
		fromHour.stringValue = String(format: "%02d", hour)
		let minute = Calendar.current.component(.minute, from: dateStart)
		fromMinute.stringValue = String(format: "%02d", minute)

		if let dateEnd = tempTracking.date_end {
			let day = Calendar.current.component(.day, from: dateEnd)
			untilDay.stringValue = String(format: "%02d", day)
			let month = Calendar.current.component(.month, from: dateEnd)
			untilMonth.stringValue = String(format: "%02d", month)
			let year = Calendar.current.component(.year, from: dateEnd)
			untilYear.stringValue = String(year)

			let hour = Calendar.current.component(.hour, from: dateEnd)
			untilHour.stringValue = String(format: "%02d", hour)
			let minute = Calendar.current.component(.minute, from: dateEnd)
			untilMinute.stringValue = String(format: "%02d", minute)
		}
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

		if let job = tempTracking.job {
			if let index = jobs.index(where: { $0.id == job.id }) {
				jobSelect.selectItem(at: index)
			}
		}
	}

	private func initTaskSelect() {
		if let tasks = QuoJob.shared.tasks {
			self.tasks = tasks
				.filter({ $0.job!.id == tempTracking.job?.id })
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

		if let task = tempTracking.task {
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
					if let job = tempTracking.job {
						return (job.type?.internal_service ?? true && $0.internal_service) || (job.type?.productive_service ?? true && $0.external_service)
					}

					return $0.internal_service || $0.nfc
				})
				.sorted(by: { $0.title! < $1.title! })
		}

		activitySelect.reloadData()

		if let activity = tempTracking.activity, let activityId = activity.id {
			if let index = activities.index(where: { $0.id == activityId }) {
				activitySelect.selectItem(at: index)
			}
		} else if let activityId = userDefaults.string(forKey: "activity") {
			if let index = activities.index(where: { $0.id == activityId }) {
				activitySelect.selectItem(at: index)
			}
		}
	}

//	private func validateData() -> Bool {
//		guard let dateEnd = tracking.date_end, let dateStart = tracking.date_start else {
//			return false
//		}
//
//		if (dateStart.compare(dateEnd) == .orderedDescending) {
//			return false
//		}
//
//		return true
//	}

	@IBAction func jobSelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			print(2)
			tempTracking.job = nil
			saveButton.isEnabled = false
		} else if let job = QuoJob.shared.jobs?.first(where: { "\($0.number ?? "number N/A") - \($0.title ?? "title N/A")".lowercased() == value }) {
			tempTracking.job = job
			saveButton.isEnabled = formIsValid
		}

		initTaskSelect()
		initActivitySelect()
	}

	@IBAction func taskSelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			tempTracking.task = nil
		} else if let task = QuoJob.shared.tasks?.first(where: { $0.title?.lowercased() == value }) {
			tempTracking.task = task
		}
	}

	@IBAction func activitySelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			jobSelect.isEnabled = true
			tempTracking.activity = nil
			saveButton.isEnabled = false
		} else if let activity = QuoJob.shared.activities?
			.filter({
				if let job = tempTracking.job {
					return (job.type?.internal_service ?? true && $0.internal_service) || (job.type?.productive_service ?? true && $0.external_service)
				}

				return $0.internal_service || $0.nfc
			})
			.first(where: { $0.title?.lowercased() == value })
		{
			if (activity.nfc) {
				jobSelect.cell?.stringValue = ""
				jobSelect.isEnabled = false
			} else {
				jobSelect.isEnabled = true
			}

			tempTracking.activity = activity
			saveButton.isEnabled = formIsValid
		}
	}

	@IBAction func deleteTracking(_ sender: NSButton) {
		guard let tracking = tracking else { return }
		context.delete(tracking)

		do {
			try context.save()
			removeFromParent()
		} catch let error {
			print(error)
		}
	}
	
	@IBAction func cancel(_ sender: NSButton) {
		removeFromParent()
	}

	@IBAction func save(_ sender: NSButton) {
		let currentTracking: Tracking!

		if let tracking = tracking {
			currentTracking = tracking
		} else {
			let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: context)
			currentTracking = NSManagedObject(entity: entity!, insertInto: context) as? Tracking
		}

		let mirror = Mirror(reflecting: tempTracking!)

		for (label, value) in mirror.children  {
			guard let label = label else { continue }

			if value is Job || value is Task || value is Activity || value is String || value is Date {
				currentTracking.setValue(value, forKey: label)
			}
		}

		currentTracking.setValue(tempTracking.job != nil ? SyncStatus.pending.rawValue : SyncStatus.error.rawValue, forKey: "exported")

		try? context.save()

		QuoJob.shared.exportTracking(tracking: currentTracking).done { result in
			if let hourbooking = result["hourbooking"] as? [String: Any], let id = hourbooking["id"] as? String {
				currentTracking.id = id
				currentTracking.exported = SyncStatus.success.rawValue
				try self.context.save()
			}
		}.catch { error in
			print("error")
			print(error)
			currentTracking.exported = SyncStatus.error.rawValue
			try? self.context.save()
		}

		removeFromParent()
	}

}

extension EditorController: NSComboBoxDataSource {
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
			return "\(job.number ?? "number N/A") - \(job.title ?? "title N/A")"
		} else if (comboBox.isEqual(taskSelect)) {
			return tasks[index].title
		} else if (comboBox.isEqual(activitySelect)) {
			return activities[index].title
		}

		return ""
	}
}

extension EditorController: DateFieldDelegate {
	func getFromMonth() -> Int? {
		return Int(fromMonth.stringValue)
	}

	func getFromYear() -> Int? {
		return Int(fromYear.stringValue)
	}

	func getUntilMonth() -> Int? {
		return Int(untilMonth.stringValue)
	}

	func getUntilYear() -> Int? {
		return Int(untilYear.stringValue)
	}
}

extension EditorController: NSTextFieldDelegate {
	func controlTextDidChange(_ obj: Notification) {
		if let textField = obj.object as? NSTextField {
			handleTextChange(in: textField)
		}

		if let comboBox = obj.object as? NSComboBox {
			handleTextChange(in: comboBox)
		}
	}

	private func handleTextChange(in textField: NSTextField) {
		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY/MM/dd HH:mm"

		if ([fromMinute, fromHour, fromDay, fromMonth, fromYear].contains(textField)) {
			if let newDate = formatter.date(from: "\(fromYear.stringValue)/\(fromMonth.stringValue)/\(fromDay.stringValue) \(fromHour.stringValue):\(fromMinute.stringValue)"),
				tempTracking.date_start.compare(newDate) != .orderedSame
			{
				tempTracking.date_start = newDate
			}
		}

		if ([untilMinute, untilHour, untilDay, untilMonth, untilYear].contains(textField)) {
			if let oldDate = tempTracking.date_end,
				let newDate = formatter.date(from: "\(untilYear.stringValue)/\(untilMonth.stringValue)/\(untilDay.stringValue) \(untilHour.stringValue):\(untilMinute.stringValue)"),
				oldDate.compare(newDate) != .orderedSame
			{
				tempTracking.date_end = newDate
			}
		}

		if (textField == comment) {
			tempTracking.comment = textField.stringValue
		}

		saveButton.isEnabled = formIsValid
	}

	private func handleTextChange(in comboBox: NSComboBox) {
		guard let comboBoxCell = comboBox.cell as? NSComboBoxCell else { return }
		let value = comboBoxCell.stringValue.lowercased()

		if (comboBox.isEqual(jobSelect)) {
			jobs = QuoJob.shared.jobs!
				.filter({ value == "" || "\($0.number!) - \($0.title!)".lowercased().contains(value) })
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
				.filter({ value == "" || $0.job!.id == tempTracking.job?.id && $0.title!.lowercased().contains(value) })
				.sorted(by: { $0.title! < $1.title! })

			if (tasks.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			}
		} else if (comboBox.isEqual(activitySelect)) {
			activities = QuoJob.shared.activities!
				.filter({
					if let job = tempTracking.job {
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
