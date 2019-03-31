//
//  TrackingViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 10.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingViewController: NSViewController, NSTextFieldDelegate {

	var timer = Timer()
	var startDate = Date()
	var currentTracking: Tracking! {
		didSet {
			if let jobs = QuoJob.shared.jobs {
				let jobTitles = jobs.sorted(by: { $0.title! < $1.title! }).map({ $0.title })
				let type = currentTracking.job?.type
				jobSelect.addItems(withTitles: jobTitles as! [String])
				jobSelect.lineBreakMode = .byTruncatingTail

				if let index = jobTitles.firstIndex(of: currentTracking.job?.title) {
					jobSelect.selectItem(at: index)
				}

				if let tasks = QuoJob.shared.tasks {
					let taskTitles = tasks.filter({ $0.job!.id == currentTracking.job!.id }).sorted(by: { $0.title! < $1.title! }).map({ $0.title })

					if (taskTitles.count > 0) {
						taskSelect.addItems(withTitles: taskTitles as! [String])
					} else {
						taskSelect.isEnabled = false
					}
				}

				if let activities = QuoJob.shared.activities {
					let activityTitles = activities.filter({ ((type?.internal_service)! && $0.internal_service) || ((type?.productive_service)! && $0.external_service) }).sorted(by: { $0.title! < $1.title! }).map({ $0.title })
					activitySelect.addItems(withTitles: activityTitles as! [String])
					activitySelect.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.5).cgColor
				}
			}
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

	let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
	var _fetchedResultsControllerTrackings: NSFetchedResultsController<Tracking>? = nil
	var fetchedResultControllerTrackings: NSFetchedResultsController<Tracking> {
		if (_fetchedResultsControllerTrackings != nil) {
			return _fetchedResultsControllerTrackings!
		}

		let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()

		fetchRequest.predicate = NSPredicate(format: "date_end == nil")

		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "date_start", ascending: true)
		]

		let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsControllerTrackings = resultsController

		do {
			try _fetchedResultsControllerTrackings!.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror)")
		}

		return _fetchedResultsControllerTrackings!
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		if let currentTracking = fetchedResultControllerTrackings.fetchedObjects?.first {
			self.currentTracking = currentTracking
		}

		activitySelect.wantsLayer = true
		activitySelect.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.5).cgColor
		commentLabel.delegate = self
		stopTracking.isEnabled = false

		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
	}

	func controlTextDidChange(_ obj: Notification) {
		guard let textField = obj.object as? NSTextField else { return }

		let text = textField.stringValue

		currentTracking.comment = text

		do {
			try context.save()
		} catch let error {
			print(error)
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

		do {
			try context.save()
		} catch let error {
			print(error)
		}
		
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
				activitySelect.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.5).cgColor
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

		do {
			try context.save()
		} catch let error {
			print(error)
		}
	}
	
	@IBAction func activitySelect(_ sender: NSPopUpButton) {
		let title = sender.titleOfSelectedItem
		guard let activity = QuoJob.shared.activities?.first(where: { $0.title == title }) else { return }

		activitySelect.layer?.backgroundColor = CGColor.clear
		stopTracking.isEnabled = true
		currentTracking.activity = activity

		do {
			try context.save()
		} catch let error {
			print(error)
		}
	}

	@IBAction func stopTracking(_ sender: NSButton) {
		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
		let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()

		fetchRequest.predicate = NSPredicate(format: "exported == nil")
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date_start", ascending: false)]

		let resultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		do {
			try resultController.performFetch()

			guard let currentTracking = resultController.fetchedObjects?.first else { return }

			currentTracking.date_end = Calendar.current.date(bySetting: .second, value: 0, of: Date())

			QuoJob.shared.exportTracking(tracking: currentTracking).done { result in
				if
					let hourbookings = result["hourbookings"] as? [[String: Any]],
					let hourbooking = hourbookings.first,
					let id = hourbooking["id"] as? String
				{
					currentTracking.id = id
					try context.save()
				}
			}.catch { error in
				print(error)
				try? context.save()
			}

			let window = (NSApp.delegate as! AppDelegate).window
			if let contentViewController = window?.contentViewController as? SplitViewController {
				contentViewController.showJobList()
			}
		} catch let error {
			print(error)
		}
	}

}
