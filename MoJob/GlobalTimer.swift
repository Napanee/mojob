//
//  GlobalTimer.swift
//  MoJob
//
//  Created by Martin Schneider on 06.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


class GlobalTimer {

	var timer: Timer = Timer()
	var currentTracking: Tracking!
	var appBadge = NSApp.dockTile as NSDockTile

	static let shared = GlobalTimer()

	private init() {}

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

	func stopTimer() {
		timer.invalidate()
		appBadge.badgeLabel = ""
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

}
