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
	private var observer: NSObjectProtocol?

	var isFavorite: Bool {
		get {
			guard let job = tracking?.job else { return false }
			return job.isFavorite
		}

		set {
			guard let currentJob = tracking?.job, let job = CoreDataHelper.mainContext.object(with: currentJob.objectID) as? Job else { return }

			currentJob.isFavorite = newValue
			job.isFavorite = newValue
			CoreDataHelper.save()

			favoriteTracking.image = newValue ? self.starFilled : self.starEmpty
		}
	}

	override var formIsValid: Bool {
		get { return super.formIsValid }
		set { stopTracking.isEnabled = newValue && super.formIsValid }
	}

	@IBOutlet weak var timeLabel: NSTextField!
	@IBOutlet weak var stopTracking: StopButton!
	@IBOutlet weak var favoriteTracking: NSButton!
	@IBOutlet weak var required: NSView!
	
	var viewHeightConstraint: NSLayoutConstraint!

	override func viewDidLoad() {
		tracking = CoreDataHelper.currentTracking

		super.viewDidLoad()

		viewHeightConstraint = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: 50)
		view.addConstraint(viewHeightConstraint)

		jobSelect.backgroundColor = NSColor.clear
		jobSelect.textColor = NSColor.white
		jobSelect.hasColoredBackground = true

		required.wantsLayer = true
		if #available(OSX 10.14, *) {
			required.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
		} else {
			required.layer?.backgroundColor = NSColor.controlHighlightColor.cgColor
		}

		if let job = tracking?.job {
			favoriteTracking.image = job.isFavorite ? starFilled : starEmpty
			favoriteTracking.state = job.isFavorite ? .on : .off
		} else {
			favoriteTracking.isHidden = true
		}

		nfc = false

		GlobalTimer.shared.stopNoTrackingTimer()

		let context = CoreDataHelper.mainContext
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(managedObjectContextDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "counter:tick"), object: nil, queue: nil, using: { notification in
			guard let totalSeconds = (notification.object as? NSDictionary)?["totalSeconds"] as? Double else { return }

			let formatter = DateComponentsFormatter()
			formatter.unitsStyle = .positional
			formatter.zeroFormattingBehavior = .pad

			if (totalSeconds < 60 * 60) { // more than an hour
				formatter.allowedUnits = [.minute, .second]
			} else {
				formatter.allowedUnits = [.hour, .minute]
			}

			self.timeLabel.stringValue = formatter.string(from: totalSeconds) ?? "00:00"
		})

		formIsValid = true

		GlobalTimer.shared.startTimer()
	}

	override func viewDidDisappear() {
		super.viewDidDisappear()

		if let observer = observer {
			NotificationCenter.default.removeObserver(observer)
		}
	}

	@IBAction func toggle(_ sender: NSButton) {
		viewHeightConstraint.constant = viewHeightConstraint.constant == 50 ? 238 : 50
		if let mainSplitViewController = parent as? MainSplitViewController {
			mainSplitViewController.toggleTracking()
		}
	}

	@IBAction func stopTracking(_ sender: NSButton) {
		guard let tracking = tracking else { return }

		tracking.stop()
	}

	@IBAction func favoriteTracking(_ sender: NSButton) {
		isFavorite = sender.state == .on
	}

	override func jobSelect(_ sender: NSComboBox) {
		super.jobSelect(sender)

		if let job = tracking?.job {
			favoriteTracking.isHidden = false
			favoriteTracking.image = job.isFavorite ? starFilled : starEmpty
			favoriteTracking.state = job.isFavorite ? .on : .off
		} else {
			favoriteTracking.isHidden = true
		}
	}

	// MARK: - Observer

	@objc func managedObjectContextDidSave(notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }

		if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
			if let job = updates.first as? Job, job.id == tracking?.job?.id {
				favoriteTracking.image = job.isFavorite ? starFilled : starEmpty
				favoriteTracking.state = job.isFavorite ? .on : .off
			}
		}
	}

}
