//
//  GlobalTimer.swift
//  MoJob
//
//  Created by Martin Schneider on 06.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


class GlobalTimer: NSObject {

	var statusItem: NSStatusItem?
	var attributes: [NSAttributedString.Key: Any] = [:]
	var timer: Timer = Timer()
	private var timerNoTracking: Timer = Timer()
	var currentTracking: Tracking!
	var appBadge = NSApp.dockTile as NSDockTile
	var completedTrackingSecondsToday: Double?
	var completedTrackingSecondsWeek: Double?

	let userDefaults = UserDefaults()
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

		statusItem = (NSApp.delegate as? AppDelegate)?.statusItem
//		statusItem?.length = 60
		statusItem?.button?.alignment = .left

		attributes[NSAttributedString.Key.foregroundColor] = NSColor.black
		attributes[NSAttributedString.Key.font] = NSFont.systemFont(ofSize: 12, weight: .medium)

		currentTracking = CoreDataHelper.currentTracking

		completedTrackingSecondsToday = CoreDataHelper.seconds(from: Date().startOfDay!, byAdding: .day)
		completedTrackingSecondsWeek = CoreDataHelper.seconds(from: Date().startOfWeek!, byAdding: .weekOfYear)

		updateTime()

		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
		RunLoop.main.add(timer, forMode: .common)
	}

	func startNoTrackingTimer() {
		let minutes = userDefaults.integer(forKey: UserDefaults.Keys.notificationNotracking)
		if (minutes == 0 || timerNoTracking.isValid || CoreDataHelper.currentTracking != nil) { return }

		timerNoTracking = Timer.scheduledTimer(timeInterval: TimeInterval(minutes * 60), target: self, selector: #selector(noTrackingNotification), userInfo: nil, repeats: false)
		RunLoop.main.add(timerNoTracking, forMode: .common)
	}

	func stopTimer() {
		timer.invalidate()
		appBadge.badgeLabel = ""

		if let statusItem = (NSApp.delegate as? AppDelegate)?.statusItem {
			statusItem.button?.imagePosition = .imageOnly
		}
	}

	func stopNoTrackingTimer() {
		timerNoTracking.invalidate()
	}

	@objc func updateTime() {
		let defaultDayHours = userDefaults.double(forKey: UserDefaults.Keys.notificationDaycomplete)
		let dayHours = userDefaults.contains(key: UserDefaults.Keys.notificationDaycomplete) ? defaultDayHours : userDefaultValues.notificationDaycomplete
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

		if (userDefaults.object(forKey: UserDefaults.Keys.badgeIconLabel) == nil || userDefaults.bool(forKey: UserDefaults.Keys.badgeIconLabel)) {
			appBadge.badgeLabel = formatter.string(from: diff)
		} else {
			appBadge.badgeLabel = ""
		}

		if let statusItem = statusItem {
			let attributed = NSAttributedString(string: formatter.string(from: diff) ?? "", attributes: attributes)
			statusItem.button?.attributedTitle = attributed
			statusItem.button?.imagePosition = .imageRight
		}

		if dayHours > 0, let completedTrackingSeconds = completedTrackingSecondsToday, completedTrackingSeconds + totalSeconds == dayHours * 3600 {
			GlobalNotification.shared.deliverNotification(
				withTitle: "Wer hat an der Uhr gedreht?",
				andInformationtext: "Ja, es ist schon so spät. Stift fallen lassen und ab nach Hause 😁"
			)
		}

		if dayHours > 0, let completedTrackingSeconds = completedTrackingSecondsWeek, completedTrackingSeconds + totalSeconds == (dayHours * 5 * 3600) {
			GlobalNotification.shared.deliverNotification(
				withTitle: "Potzblitz. Die Woche ist schon wieder rum!",
				andInformationtext: "Wenn du es also mit deinem Gewissen vereinbaren kannst: Ab ins Wochenende 🤪"
			)
		}

		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "counter:tick"), object: ["totalSeconds": totalSeconds])
	}

	@objc func noTrackingNotification() {
		guard (timerNoTracking.isValid && CoreDataHelper.currentTracking == nil) else { return }

		GlobalNotification.shared.deliverNotification(
			withTitle: "Der Timer läuft nicht",
			andInformationtext: "Na? Wollen wir dann auch mal wieder arbeiten? 🧐"
		)
	}

}

extension GlobalTimer: NSUserNotificationCenterDelegate {

	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}

}
