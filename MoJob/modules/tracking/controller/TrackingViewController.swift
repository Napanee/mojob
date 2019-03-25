//
//  TrackingViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 10.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingViewController: NSViewController {

	var timer = Timer()
	var timeInSec = 0
	var counter: CGFloat = 0

	@IBOutlet weak var timerCount: TimerCount!
	@IBOutlet weak var timeLabel: NSTextField!
	@IBOutlet weak var jobLabel: TextField!
	@IBOutlet weak var taskLabel: TextField!
	@IBOutlet weak var activityLabel: TextField!
	@IBOutlet weak var commentLabel: TextField!

	override func viewDidLoad() {
		super.viewDidLoad()

		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
	}

	@objc func updateTime() {
		counter = counter + 1

		if (counter > 60) {
			counter = 1
		}

		timeInSec = timeInSec + 1
		timerCount.counter = counter
		timeLabel.stringValue = secondsToHoursMinutesSeconds(sec: timeInSec)
	}

	@IBAction func stopTracking(_ sender: NSButton) {
		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
		let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()

		fetchRequest.predicate = NSPredicate(format: "exported == nil")
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date_start", ascending: false)]

		let resultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		do {
			try resultController.performFetch()

			let currentTracking = resultController.fetchedObjects?.first
			currentTracking?.date_end = Calendar.current.date(bySetting: .second, value: 0, of: Date())

			try context.save()

			let window = (NSApp.delegate as! AppDelegate).window
			if let contentViewController = window?.contentViewController as? SplitViewController {
				contentViewController.showJobList()
			}
		} catch let error {
			print(error)
		}
	}

}