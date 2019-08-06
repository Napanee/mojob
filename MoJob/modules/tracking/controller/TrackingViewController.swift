//
//  TrackingViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 10.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingViewController: QuoJobSelections {

	let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
	let starFilled = NSImage(named: "star-filled")?.tint(color: NSColor.systemYellow)
	let starEmpty = NSImage(named: "star-empty")

	var appBadge = NSApp.dockTile as NSDockTile
	var timer = Timer()

	var isFavorite: Bool {
		get {
			guard let job = tempTracking.job else { return false }
			return job.isFavorite
		}

		set {
			guard let job = tempTracking.job else { return }

			job.isFavorite = newValue
			favoriteTracking.image = newValue ? starFilled : starEmpty

			guard let _ = try? context.save() else {
				job.isFavorite = !newValue
				favoriteTracking.image = !newValue ? starFilled : starEmpty
				return
			}
		}
	}

	override var formIsValid: Bool {
		get { return super.formIsValid }
		set { stopTracking.isEnabled = newValue && super.formIsValid }
	}

	@IBOutlet weak var timerCount: TimerCount!
	@IBOutlet weak var timeLabel: NSTextField!
	@IBOutlet weak var commentLabel: TextField!
	@IBOutlet weak var stopTracking: NSButton!
	@IBOutlet weak var favoriteTracking: NSButton!
	
	override func viewDidLoad() {
		tempTracking = (NSApp.delegate as! AppDelegate).currentTracking

		super.viewDidLoad()

		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
		RunLoop.main.add(timer, forMode: .common)

		if let job = tempTracking.job {
			favoriteTracking.image = job.isFavorite ? starFilled : starEmpty
			favoriteTracking.state = job.isFavorite ? .on : .off
		} else {
			favoriteTracking.isHidden = true
		}

		taskSelect.font = NSFont.systemFont(ofSize: 14, weight: .light)
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
