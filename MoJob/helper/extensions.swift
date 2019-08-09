//
//  extensions.swift
//  MoJob
//
//  Created by Martin Schneider on 01.04.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import AppKit
import Foundation

extension QuoJob.Method {
	static let myTime_putHourbooking = "mytime.put_hourbooking"
	static let myTime_getHourbookingChanges = "mytime.get_hourbooking_changes"
	static let myTime_getHourbookings = "mytime.get_hourbookings"
	static let myTime_deleteHourbooking = "mytime.delete_hourbooking"
	static let session_getCurrentUser = "session.get_current_user"
	static let session_login = "session.login"
	static let job_getJobtypes = "job.get_jobtypes"
	static let job_getJobs = "job.get_jobs"
	static let common_getActivities = "common.get_activities"
	static let job_getJobtasks = "job.get_jobtasks"
}

extension NSNib.Name {
	static let addFavoriteNib = "AddFavorite"
	static let loginNib = "Login"
	static let splitTrackingNib = "SplitTracking"
	static let navigationControllerNib = "NavigationController"
	static let jobListControllerNib = "JobListController"
	static let favoritesCollectionItemNib = "FavoriteItem"
	static let jobsCollectionItemNib = "JobItem"
	static let trackingViewControllerNib = "TrackingViewController"
	static let dayTrackingsControllerNib = "DayTrackingsController"
	static let editorControllerNib = "EditorController"
	static let wakeUpController = "WakeUp"
}

extension NSImage.Name {
	static let checkedImage = "checked"
	static let deleteImage = "delete"
	static let loginImage = "login"
	static let playImage = "play"
	static let reloadImage = "reload"
	static let settingsActiveImage = "settings-active"
	static let settingsImage = "settings"
	static let starEmptyImage = "star-empty"
	static let starFilledImage = "star-filled"
	static let stopImage = "stop"
	static let syncErrorImage = "sync-error"
	static let syncPendingImage = "sync-pending"
	static let syncSuccessImage = "sync-success"
	static let timerActiveImage = "timer-active"
	static let timerImage = "timer"
	static let uncheckedImage = "unchecked"
	static let radioUncheckedImage = "radio-unchecked"
	static let radioCheckedImage = "radio-checked"
}

extension UserDefaults {
	public typealias Keys = String

	func contains(key: String) -> Bool {
		return UserDefaults.standard.object(forKey: key) != nil
	}
}

extension UserDefaults.Keys {
	static let notificationNotracking = "notification:notracking"
	static let notificationDaycomplete = "notification:daycomplete"
	static let activity = "activity"
}

extension NSImage {
	func tint(color: NSColor) -> NSImage {
		let image = self.copy() as! NSImage
		image.lockFocus()

		color.set()

		let imageRect = NSRect(origin: NSZeroPoint, size: image.size)
		imageRect.fill(using: .sourceAtop)

		image.unlockFocus()

		return image
	}
}

extension Date {
	var month: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "MMMM"
		dateFormatter.locale = Locale(identifier: "de_DE")
		return dateFormatter.string(from: self)
	}

	var day: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd"
		dateFormatter.locale = Locale(identifier: "de_DE")
		return dateFormatter.string(from: self)
	}

	var year: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "YYYY"
		dateFormatter.locale = Locale(identifier: "de_DE")
		return dateFormatter.string(from: self)
	}

	var fullDateString: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "YYYYMMddHHmmss"
		return dateFormatter.string(from: self)
	}

	var startOfDay: Date? {
		return Calendar.current.date(from: Calendar.current.dateComponents([.day, .month, .year], from: self))
	}

	var endOfDay: Date? {
		return Calendar.current.date(byAdding: .day, value: 1, to: self.startOfDay!)
	}

	var startOfWeek: Date? {
		return Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
	}

	var endOfWeek: Date? {
		return Calendar.current.date(byAdding: .day, value: 7, to: self.startOfWeek!)
	}
}
