//
//  TrackingViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 10.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingViewController: QuoJobSelections {

	private var observer: NSObjectProtocol?

	var isFavorite: Bool {
		get {
			return CoreDataHelper.favorite(job: tracking?.job, task: tracking?.task, activity: tracking?.activity) != nil
		}

		set {
			if (!newValue && isFavorite) {
				CoreDataHelper.deleteFavorite(job: tracking?.job, task: tracking?.task, activity: tracking?.activity)

				favoriteTracking.state = .off
			}

			if (newValue && !isFavorite) {
				let indexJob = jobSelect.indexOfSelectedItem
				let indexTask = taskSelect.indexOfSelectedItem
				let indexActivity = activitySelect.indexOfSelectedItem

				var job: Job?
				var task: Task?
				var activity: Activity?

				if (indexJob >= 0 && jobs.count > indexJob) {
					job = jobs[indexJob]
				}

				if (indexTask >= 0 && tasks.count > indexTask) {
					task = tasks[indexTask]
				}

				if (indexActivity >= 0 && activities.count > indexActivity) {
					activity = activities[indexActivity]
				}

				CoreDataHelper.createFavorite(job: job, task: task, activity: activity)

				favoriteTracking.state = .on
			}
		}
	}

	override var formIsValid: Bool {
		get { return super.formIsValid }
		set { stopTracking.isEnabled = newValue && super.formIsValid }
	}

	@IBOutlet weak var timeLabel: NSTextField!
	@IBOutlet weak var stopTracking: StopButton!
	@IBOutlet weak var favoriteTracking: NSButton!
	@IBOutlet weak var toggleButton: ToggleButton!
	@IBOutlet weak var required: NSView!
	
	var viewHeightConstraint: NSLayoutConstraint!

	override func viewDidLoad() {
		super.viewDidLoad()

		nfc = false
		delegate = self

		tracking = CoreDataHelper.currentTracking

		viewHeightConstraint = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: .none, attribute: .notAnAttribute, multiplier: 1, constant: 50)
		view.addConstraint(viewHeightConstraint)

		jobSelect.backgroundColor = NSColor.clear
		jobSelect.textColor = NSColor.white
		jobSelect.hasColoredBackground = true

		required.wantsLayer = true
		if #available(OSX 10.14, *) {
			required.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
		} else {
			required.layer?.backgroundColor = CGColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 1.0)
		}

		favoriteTracking.state = isFavorite ? .on : .off
		favoriteTracking.isHidden = tracking?.job == nil

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

		if let duration = tracking?.duration, duration < 1.0 {
			toggleButton.state = .on
			toggle()
		}
	}

	override func viewDidDisappear() {
		super.viewDidDisappear()

		if let observer = observer {
			NotificationCenter.default.removeObserver(observer)
		}
	}

	private func toggle() {
		viewHeightConstraint.constant = viewHeightConstraint.constant == 50 ? 238 : 50
		if let mainSplitViewController = parent as? MainSplitViewController {
			mainSplitViewController.toggleTracking()
		}
	}

	@IBAction func toggle(_ sender: NSButton) {
		toggle()
	}

	@IBAction func stopTracking(_ sender: NSButton) {
		guard let tracking = tracking else { return }

		tracking.stop()
	}

	@IBAction func favoriteTracking(_ sender: NSButton) {
		isFavorite = sender.state == .on
	}

	override func comboBoxWillDismiss(_ notification: Notification) {
		super.comboBoxWillDismiss(notification)

		guard let comboBox = notification.object as? NSComboBox else { return }

		if (comboBox.isEqual(jobSelect)) {
			favoriteTracking.state = isFavorite ? .on : .off
			favoriteTracking.isHidden = tracking?.job == nil
		}
	}

	// MARK: - Observer

	@objc func managedObjectContextDidSave(notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }

		if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
			if let _ = inserts.first as? Favorite {
				favoriteTracking.state = isFavorite ? .on : .off
				favoriteTracking.isHidden = tracking?.job == nil
			}
		}

		if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
			if let _ = deletes.first as? Favorite {
				favoriteTracking.state = isFavorite ? .on : .off
				favoriteTracking.isHidden = tracking?.job == nil
			}
		}
	}

}
