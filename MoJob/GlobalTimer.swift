//
//  GlobalTimer.swift
//  MoJob
//
//  Created by Martin Schneider on 06.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


class GlobalTimer: NSObject {

	var timer: Timer = Timer()
	private var timerNoTracking: Timer = Timer()
	var currentTracking: Tracking!
	var appBadge = NSApp.dockTile as NSDockTile

	static let shared = GlobalTimer()

	private override init() {
		super.init()

		NSUserNotificationCenter.default.delegate = self
	}

	func startTimer() {
		if (timer.isValid) {
			updateTime()
			return
		}

		currentTracking = CoreDataHelper.shared.currentTracking
		updateTime()

		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
		RunLoop.main.add(timer, forMode: .common)
	}

	func startNoTrackingTimer() {
		if (timerNoTracking.isValid || CoreDataHelper.shared.currentTracking != nil) { return }
print("start timer")
		timerNoTracking = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(noTrackingNotification), userInfo: nil, repeats: false)
		RunLoop.main.add(timerNoTracking, forMode: .common)
	}

	func stopTimer() {
		timer.invalidate()
		appBadge.badgeLabel = ""
	}

	func stopNoTrackingTimer() {
		print("stop timer")
		timerNoTracking.invalidate()
	}

	@objc func updateTime() {
		let currentDate = Date()
		let diff = currentDate.timeIntervalSince(currentTracking.date_start ?? Date())
		let totalSeconds = round(diff)

		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .positional
		formatter.zeroFormattingBehavior = .pad

		if (totalSeconds < 60 * 60) { // more than an hour
			formatter.allowedUnits = [.minute, .second]
		} else {
			formatter.allowedUnits = [.hour, .minute]
		}

		appBadge.badgeLabel = formatter.string(from: diff)

		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "counter:tick"), object: ["totalSeconds": totalSeconds])
	}

	@objc func noTrackingNotification() {
		guard (timerNoTracking.isValid && CoreDataHelper.shared.currentTracking == nil) else { return }

		let notification = NSUserNotification()
		notification.title = "Der Timer läuft nicht"
		notification.informativeText = "Vergessen zu starten?"
		notification.soundName = NSUserNotificationDefaultSoundName
		NSUserNotificationCenter.default.deliver(notification)
	}

}

extension GlobalTimer: NSUserNotificationCenterDelegate {

	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}

}
