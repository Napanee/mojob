//
//  TrackingViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 10.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingViewController: NSViewController {

	let starFilled = NSImage(named: "star-filled")?.tint(color: NSColor.systemYellow)
	let starEmpty = NSImage(named: "star-empty")
	let userDefaults = UserDefaults()

	var jobs: [Job] = []
	var tasks: [Task] = []
	var activities: [Activity] = []

	var tempTracking: TempTracking!
	var formIsValid: Bool {
		get {
			if (
				tempTracking.activity != nil &&
				(tempTracking.date_end ?? Date()).timeIntervalSince(tempTracking.date_start) > 60 &&
				(tempTracking.job != nil || tempTracking.custom_job != nil)
			) {
				return true
			}

			return false
		}
	}

	var appBadge = NSApp.dockTile as NSDockTile
	var timer = Timer()
	var startDate = Date()
	var isFavorite: Bool {
		set {
			if let job = tempTracking.job {
				job.isFavorite = newValue
			}

			if (newValue) {
				favoriteTracking.image = starFilled
			} else {
				favoriteTracking.image = starEmpty
			}

			do {
				try context.save()
			} catch let error {
				print(error)
			}
		}

		get {
			if let job = tempTracking.job {
				return job.isFavorite
			}

			return false
		}
	}

	let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext

	@IBOutlet weak var timerCount: TimerCount!
	@IBOutlet weak var timeLabel: NSTextField!
	@IBOutlet weak var fromHour: NumberField!
	@IBOutlet weak var fromMinute: NumberField!
	@IBOutlet weak var commentLabel: TextField!
	@IBOutlet weak var comment: NSTextField!
	@IBOutlet weak var jobSelect: NSComboBox!
	@IBOutlet weak var taskSelect: NSComboBox!
	@IBOutlet weak var activitySelect: NSComboBox!
	@IBOutlet weak var stopTracking: NSButton!
	@IBOutlet weak var favoriteTracking: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
		RunLoop.main.add(timer, forMode: .common)

		tempTracking = (NSApp.delegate as! AppDelegate).currentTracking

		if let job = tempTracking.job {
			if (job.isFavorite) {
				favoriteTracking.image = starFilled
				favoriteTracking.state = .on
			} else {
				favoriteTracking.image = starEmpty
				favoriteTracking.state = .off
			}
		} else {
			favoriteTracking.isHidden = true
		}

		let dateStart = tempTracking.date_start
		let hour = Calendar.current.component(.hour, from: dateStart)
		fromHour.stringValue = String(format: "%02d", hour)
		let minute = Calendar.current.component(.minute, from: dateStart)
		fromMinute.stringValue = String(format: "%02d", minute)

		commentLabel.delegate = self

		initJobSelect()
		initTaskSelect()
		initActivitySelect()
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
		} else if let customJob = tempTracking.custom_job {
			jobSelect.stringValue = customJob
		}
	}

	private func initTaskSelect() {
		if let tasks = QuoJob.shared.tasks {
			self.tasks = tasks
				.filter({ $0.job!.id == tempTracking.job?.id })
				.sorted(by: { $0.title! < $1.title! })
		}

		taskSelect.font = NSFont.systemFont(ofSize: 14, weight: .light)

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

					return $0.internal_service
				})
				.sorted(by: { $0.title! < $1.title! })
		}

		activitySelect.reloadData()

		if let activity = tempTracking.activity, let activityId = activity.id {
			if let index = activities.index(where: { $0.id == activityId }) {
				activitySelect.selectItem(at: index)
			}
		} else if let activityId = userDefaults.string(forKey: "activity") {
			if let activity = activities.first(where: { $0.id == activityId }), let index = activities.index(where: { $0 == activity }) {
				activitySelect.selectItem(at: index)
				tempTracking.activity = activity
			}
		}
	}

	@objc func updateTime() {
		let currentDate = Date()
		let diff = currentDate.timeIntervalSince(startDate)
		let restSeconds = diff.remainder(dividingBy: 60)
		let totalSeconds = Int(round(diff))

		timerCount.counter = round(CGFloat(restSeconds))
		timeLabel.stringValue = secondsToHoursMinutesSeconds(sec: totalSeconds)


		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .positional
		formatter.zeroFormattingBehavior = .pad

		if (totalSeconds < 60 * 60) { // more than an hour
			formatter.allowedUnits = [.minute, .second]
		} else {
			formatter.allowedUnits = [.hour, .minute]
		}

		appBadge.badgeLabel = formatter.string(from: diff)
	}

	@IBAction func jobSelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			tempTracking.job = nil
			tempTracking.task = nil
		} else if let job = QuoJob.shared.jobs?.first(where: { "\($0.number ?? "number N/A") - \($0.title ?? "title N/A")".lowercased() == value }) {
			tempTracking.job = job
		} else {
			tempTracking.job = nil
			tempTracking.custom_job = value
		}

		stopTracking.isEnabled = formIsValid

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
			tempTracking.activity = nil
			stopTracking.isEnabled = false
		} else if let activity = QuoJob.shared.activities?
			.filter({
				if let job = tempTracking.job {
					return (job.type?.internal_service ?? true && $0.internal_service) || (job.type?.productive_service ?? true && $0.external_service)
				}

				return $0.internal_service
			})
			.first(where: { $0.title?.lowercased() == value })
		{
			tempTracking.activity = activity
			stopTracking.isEnabled = formIsValid
		}
	}

	@IBAction func stopTracking(_ sender: NSButton) {
		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext

		guard let tempTracking = tempTracking else { return }

		let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: context)
		let tracking = NSManagedObject(entity: entity!, insertInto: context)
		let mirror = Mirror(reflecting: tempTracking)

		for (label, value) in mirror.children  {
			guard let label = label else { continue }

			if value is Job || value is Task || value is Activity || value is String || value is Date {
				tracking.setValue(value, forKey: label)
			}
		}

		tracking.setValue(Calendar.current.date(bySetting: .second, value: 0, of: Date()), forKey: "date_end")
		tracking.setValue(tempTracking.job != nil ? SyncStatus.pending.rawValue : SyncStatus.error.rawValue, forKey: "exported")

		try? context.save()

		if let _ = tempTracking.job, let tracking = tracking as? Tracking {
			QuoJob.shared.exportTracking(tracking: tracking).done { result in
				if
					let hourbooking = result["hourbooking"] as? [String: Any],
					let id = hourbooking["id"] as? String
				{
					tracking.id = id
					tracking.exported = SyncStatus.success.rawValue
					try context.save()
				}
			}.catch { error in
				tracking.exported = SyncStatus.error.rawValue
				try? context.save()
				print(error)
			}
		}

		timer.invalidate()
		appBadge.badgeLabel = ""

		if let appDelegate = NSApp.delegate as? AppDelegate, let mainWindowController = appDelegate.mainWindowController, let contentViewController = mainWindowController.currentContentViewController as? TrackingSplitViewController {
			contentViewController.showJobList()
		}
	}

	@IBAction func favoriteTracking(_ sender: NSButton) {
		isFavorite = sender.state == .on
	}

}

extension TrackingViewController: NSComboBoxDataSource {
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

extension TrackingViewController: NSTextFieldDelegate {
	func controlTextDidChange(_ obj: Notification) {
		if let textField = obj.object as? NSTextField {
			handleTextChange(in: textField)
		}

		if let comboBox = obj.object as? NSComboBox {
			handleTextChange(in: comboBox)
		}
	}

	private func handleTextChange(in textField: NSTextField) {
		if ([fromHour, fromMinute].contains(textField)) {
			let comp = Calendar.current.dateComponents([.hour, .minute], from: tempTracking.date_start)
			let hour = fromHour.stringValue != "" ? Int(fromHour.stringValue) : comp.hour
			let minute = fromMinute.stringValue != "" ? Int(fromMinute.stringValue) : comp.minute
			let newStartDate = Calendar.current.date(bySettingHour: hour!, minute: minute!, second: 0, of: tempTracking.date_start)!

			tempTracking.date_start = newStartDate
			startDate = newStartDate
			stopTracking.isEnabled = formIsValid
		}

		if (textField == comment) {
			tempTracking.comment = textField.stringValue
		}
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
