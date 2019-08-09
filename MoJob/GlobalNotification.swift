//
//  Notification.swift
//  MoJob
//
//  Created by Martin Schneider on 09.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class GlobalNotification: NSObject {

	static let shared = GlobalNotification()
	let notificationCenter = NSUserNotificationCenter.default

	private override init() {
		super.init()

		NSUserNotificationCenter.default.delegate = self
	}

	func deliverNotification(withTitle title: String, andInformationtext text: String? = nil) {
		let notification = NSUserNotification()
		notification.title = title
		if let text = text {
			notification.informativeText = text
		}
		notification.soundName = NSUserNotificationDefaultSoundName
		notificationCenter.deliver(notification)
	}

	func deliverNotLoggedIn(withInformationText text: String? = nil) {
		deliverNotification(
			withTitle: "Du bist nicht eingeloggt.",
			andInformationtext: text ?? "Damit deine Trackings automatisch übertragen werden können, solltest du dich einloggen."
		)
	}

}

extension GlobalNotification: NSUserNotificationCenterDelegate {

	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}

}
