//
//  TrackingViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 10.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingViewController: QuoJobSelections {

	let starFilled = NSImage(named: .starFilledImage)?.tint(color: NSColor.systemYellow)
	let starEmpty = NSImage(named: .starEmptyImage)
	private var observer: NSObjectProtocol!

	var isFavorite: Bool {
		get {
			guard let job = tracking?.job else { return false }
			return job.isFavorite
		}

		set {
			guard let job = tracking?.job else { return }

			job.update(with: ["isFavorite": newValue]).done({ _ in
				self.favoriteTracking.image = newValue ? self.starFilled : self.starEmpty
			}).catch({ _ in
				job.isFavorite = !newValue
				self.favoriteTracking.image = !newValue ? self.starFilled : self.starEmpty
			})
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
		tracking = CoreDataHelper.shared.currentTracking

		super.viewDidLoad()

		if let job = tracking?.job {
			favoriteTracking.image = job.isFavorite ? starFilled : starEmpty
			favoriteTracking.state = job.isFavorite ? .on : .off
		} else {
			favoriteTracking.isHidden = true
		}

		taskSelect.font = NSFont.systemFont(ofSize: 14, weight: .light)

		nfc = false

		GlobalTimer.shared.stopNoTrackingTimer()
	}

	override func viewDidAppear() {
		observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "counter:tick"), object: nil, queue: nil, using: { notification in
			guard let totalSeconds = (notification.object as? NSDictionary)?["totalSeconds"] as? Double else { return }

			let restSeconds = totalSeconds.remainder(dividingBy: 60)
			self.timerCount.counter = round(CGFloat(restSeconds))
			self.timeLabel.stringValue = secondsToHoursMinutesSeconds(sec: Int(totalSeconds))

			if (totalSeconds > 60) {
				self.formIsValid = true
			}
		})

		GlobalTimer.shared.startTimer()
	}

	override func viewDidDisappear() {
		super.viewDidDisappear()
		NotificationCenter.default.removeObserver(observer)
	}

	func reRender() {
		tracking = CoreDataHelper.shared.currentTracking
		GlobalTimer.shared.stopNoTrackingTimer()
		GlobalTimer.shared.startTimer()

		initStartDate()

		formIsValid = true
	}

	@IBAction func stopTracking(_ sender: NSButton) {
		guard let tracking = tracking else { return }

		tracking.stop()

		if let appDelegate = NSApp.delegate as? AppDelegate, let mainWindowController = appDelegate.mainWindowController, let contentViewController = mainWindowController.currentContentViewController as? TrackingSplitViewController {
			contentViewController.showJobList()
		}
	}

	@IBAction func favoriteTracking(_ sender: NSButton) {
		isFavorite = sender.state == .on
	}

}
