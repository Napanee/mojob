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
			guard let job = tracking?.job else { return }

			job.isFavorite = newValue

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

		taskSelect.font = NSFont.systemFont(ofSize: 14, weight: .light)

		nfc = false

		GlobalTimer.shared.stopNoTrackingTimer()
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		jobSelect.backgroundColor = NSColor.clear
		jobSelect.textColor = NSColor.white
		stopTracking.image = stopTracking.image?.tint(color: NSColor.white)

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

	func reRender() {
		tracking = CoreDataHelper.currentTracking
		GlobalTimer.shared.stopNoTrackingTimer()
		GlobalTimer.shared.startTimer()

		initStartDate()

		formIsValid = true
	}

	@IBAction func toggle(_ sender: NSButton) {
		viewHeightConstraint.constant = viewHeightConstraint.constant == 50 ? 238 : 50
		if let mainSplitViewController = parent as? MainSplitViewController {
			mainSplitViewController.toggleTracking()
		}
	}

	@IBAction func stopTracking(_ sender: NSButton) {
		guard let tracking = tracking else { return }

		if (Date().timeIntervalSince(tracking.date_start!) < 60) {
			let question = "Tracking wird verworfen. Möchtest du fortfahren?"
			let info = "QuoJob akzeptiert nur Trackings, die mindestens eine Minute dauern."
			let confirmButton = "Tracking verwerfen"
			let cancelButton = "Abbrechen"
			let alert = NSAlert()
			alert.messageText = question
			alert.informativeText = info
			alert.addButton(withTitle: confirmButton)
			alert.addButton(withTitle: cancelButton)

			let answer = alert.runModal()
			if answer == .alertSecondButtonReturn {
				return
			} else {
				tracking.managedObjectContext?.reset()
				GlobalTimer.shared.startNoTrackingTimer()
				GlobalTimer.shared.stopTimer()
			}
		} else {
			tracking.stop()
		}

		(NSApp.mainWindow?.windowController as? MainWindowController)?.mainSplitViewController?.removeTracking()
	}

	@IBAction func favoriteTracking(_ sender: NSButton) {
		isFavorite = sender.state == .on
	}

}
