//
//  TrackingViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 10.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingViewController: NSViewController, NSTextFieldDelegate {

	let starFilled = NSImage(named: "star-filled")?.tint(color: NSColor.systemYellow)
	let starEmpty = NSImage(named: "star-empty")
	let userDefaults = UserDefaults()

	var timer = Timer()
	var startDate = Date()
	var currentTracking: TempTracking!
	var isFavorite: Bool {
		set {
			if let job = currentTracking.job {
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
			if let job = currentTracking.job {
				return job.isFavorite
			}

			return false
		}
	}

	@IBOutlet weak var timerCount: TimerCount!
	@IBOutlet weak var timeLabel: NSTextField!
//	@IBOutlet weak var jobLabel: TextField!
//	@IBOutlet weak var taskLabel: TextField!
//	@IBOutlet weak var activityLabel: TextField!
	@IBOutlet weak var commentLabel: TextField!
	@IBOutlet weak var jobSelect: NSPopUpButton!
	@IBOutlet weak var taskSelect: NSPopUpButton!
	@IBOutlet weak var activitySelect: NSPopUpButton!
	@IBOutlet weak var stopTracking: NSButton!
	@IBOutlet weak var favoriteTracking: NSButton!

	let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
	
	override func viewDidLoad() {
		super.viewDidLoad()

		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
		RunLoop.main.add(timer, forMode: .common)

		currentTracking = (NSApp.delegate as! AppDelegate).currentTracking

		if let job = currentTracking.job {
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

		commentLabel.delegate = self
		stopTracking.isEnabled = false

		initJobSelect()
		initTaskSelect()
		initActivitySelect()
	}

	func controlTextDidChange(_ obj: Notification) {
		guard let textField = obj.object as? NSTextField else { return }

		let text = textField.stringValue

		currentTracking.comment = text
	}

	func initJobSelect() {
		if let jobs = QuoJob.shared.jobs {
			let jobTitles: [String] = jobs.sorted(by: { $0.title! < $1.title! }).map({ $0.title! })

			if let customJobTitle = currentTracking.custom_job {
				jobSelect.addItem(withTitle: customJobTitle)
			}

			jobSelect.addItems(withTitles: jobTitles)
			jobSelect.lineBreakMode = .byTruncatingTail

			if let job = currentTracking.job, let index = jobTitles.firstIndex(of: job.title!) {
				jobSelect.selectItem(at: index)
			}
		}
	}

	func initTaskSelect() {
		taskSelect.isEnabled = false

		if let tasks = QuoJob.shared.tasks, let job = currentTracking.job, let jobId = job.id {
			let taskTitles: [String] = tasks.filter({ $0.job!.id == jobId })
				.sorted(by: { $0.title! < $1.title! })
				.map({ $0.title! })

			if (taskTitles.count > 0) {
				taskSelect.addItems(withTitles: taskTitles)
				taskSelect.isEnabled = true
			}
		}
	}

	func initActivitySelect() {
		if let activities = QuoJob.shared.activities {
			let activityTitles: [String] = activities.filter({ (activity: Activity) -> Bool in
				guard let job = currentTracking.job, let type = job.type else { return activity.external_service }

				return (type.internal_service && activity.internal_service) || (type.productive_service && activity.external_service)
			}).sorted(by: { $0.title! < $1.title! }).map({ $0.title! })

			activitySelect.addItems(withTitles: activityTitles)

			if
				let activityId = userDefaults.object(forKey: "activity") as? String,
				let activity = activities.first(where: { $0.id == activityId }),
				let title = activity.title,
				let index = activityTitles.firstIndex(of: title)
			{
				currentTracking.activity = activity
				activitySelect.selectItem(at: index + 1)
				stopTracking.isEnabled = true
			}
		}
	}

	@objc func updateTime() {
		let currentDate = Date()
		let diff = currentDate.timeIntervalSince(startDate)
		let restSeconds = diff.remainder(dividingBy: 60)

		timerCount.counter = round(CGFloat(restSeconds))
		timeLabel.stringValue = secondsToHoursMinutesSeconds(sec: Int(round(diff)))
	}

	@IBAction func jobSelect(_ sender: NSPopUpButton) {
		let title = sender.titleOfSelectedItem
		let currentActivity = activitySelect.titleOfSelectedItem
		guard let job = QuoJob.shared.jobs?.first(where: { $0.title == title }) else { return }

		let type = job.type

		currentTracking.job = job
		currentTracking.task = nil
		taskSelect.removeAllItems()
		activitySelect.removeAllItems()
		
		if let tasks = QuoJob.shared.tasks {
			let taskTitles = tasks.filter({ $0.job!.id == job.id }).sorted(by: { $0.title! < $1.title! }).map({ $0.title })

			if (taskTitles.count > 0) {
				taskSelect.addItem(withTitle: "Aufgabe wählen")
				taskSelect.addItems(withTitles: taskTitles as! [String])
				taskSelect.isEnabled = true
			} else {
				taskSelect.isEnabled = false
			}
		}

		if let activities = QuoJob.shared.activities {
			let activityTitles = activities.filter({ ((type?.internal_service)! && $0.internal_service) || ((type?.productive_service)! && $0.external_service) }).sorted(by: { $0.title! < $1.title! }).map({ $0.title })
			activitySelect.addItem(withTitle: "Leistungsart wählen")
			activitySelect.addItems(withTitles: activityTitles as! [String])

			if let currentActivity = currentActivity, let currentIndex = activitySelect.itemTitles.firstIndex(of: currentActivity) {
				activitySelect.selectItem(at: currentIndex)
			} else {
				stopTracking.isEnabled = false
			}
		}
	}

	@IBAction func taskSelect(_ sender: NSPopUpButton) {
		let title = sender.titleOfSelectedItem
		if let task = QuoJob.shared.tasks?.first(where: { $0.title == title }) {
			currentTracking.task = task
		} else {
			currentTracking.task = nil
		}
	}
	
	@IBAction func activitySelect(_ sender: NSPopUpButton) {
		let title = sender.titleOfSelectedItem
		guard let activity = QuoJob.shared.activities?.first(where: { $0.title == title }) else { return }

		activitySelect.layer?.backgroundColor = CGColor.clear
		stopTracking.isEnabled = true
		currentTracking.activity = activity

		userDefaults.set(activity.id, forKey: "activity")
	}

	@IBAction func stopTracking(_ sender: NSButton) {
		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext

		guard let currentTracking = currentTracking else { return }

		let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: context)
		let tracking = NSManagedObject(entity: entity!, insertInto: context)
		let mirror = Mirror(reflecting: currentTracking)

		for (label, value) in mirror.children  {
			guard let label = label else { continue }

			if value is Job || value is Task || value is Activity || value is String || value is Date {
				tracking.setValue(value, forKey: label)
			}
		}

		tracking.setValue(Calendar.current.date(bySetting: .second, value: 0, of: Date()), forKey: "date_end")
		tracking.setValue(currentTracking.job != nil ? SyncStatus.pending.rawValue : SyncStatus.error.rawValue, forKey: "exported")

		try? context.save()

		if let _ = currentTracking.job, let tracking = tracking as? Tracking {
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

		let window = (NSApp.delegate as! AppDelegate).window
		if let contentViewController = window?.contentViewController as? SplitViewController {
			contentViewController.showJobList()
		}
	}

	@IBAction func favoriteTracking(_ sender: NSButton) {
		isFavorite = sender.state == .on
	}

}
