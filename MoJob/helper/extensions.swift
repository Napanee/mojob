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
	static let session_isConnectionPossible = "session.is_connection_possible"
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
	static let calendarControllerNib = "CalendarController"
	static let statsControllerNib = "StatsViewController"
	static let settingsControllerNib = "SettingsViewController"
}

extension NSImage.Name {
	static let syncErrorImage = "sync-error"
	static let syncPendingImage = "sync-pending"
	static let syncSuccessImage = "sync-success"
	static let statusBarImage = "statusIcon"
}

extension NSColorList {
	static var moJobColorList: NSColorList {
		get {
			let path = Bundle.main.path(forResource: "MoJob", ofType: "clr")
			return NSColorList(name: "MoJob", fromFile: path)!
		}
	}
}

extension UserDefaults {
	public typealias Keys = String
	public typealias Values = String

	public enum workWeek {
		static let standard = "standard"
		static let special = "special"
	}
}

extension UserDefaults.Keys {
	static let autoLaunch = "autoLaunch"
	static let notificationNotracking = "notification:notracking"
	static let notificationDaycomplete = "notification:daycomplete"
	static let activity = "activity"
	static let badgeIconLabel = "badgeIconLabel"
	static let syncOnStart = "syncOnStart"
	static let crashOnSync = "crashOnSync"
	static let workWeek = "workWeek"
	static let evenWeekDays = "evenWeekDays"
	static let oddWeekDays = "oddWeekDays"
	static let evenWeekHours = "evenWeekHours"
	static let oddWeekHours = "oddWeekHours"
	static let taskHoursInterval = "taskHoursInterval"
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
	var asString: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd.MM.YYYY HH:mm"
		dateFormatter.locale = Locale(identifier: "de_DE")
		return dateFormatter.string(from: self)
	}

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

	var startOfMonth: Date? {
		return Calendar.current.date(from: Calendar.current.dateComponents([.month, .year], from: self))
	}

	var endOfMonth: Date? {
		let firstDayOfNextMonth = Calendar.current.date(byAdding: .month, value: 1, to: self.startOfMonth!)
		return Calendar.current.date(byAdding: .second, value: -1, to: firstDayOfNextMonth!)
	}

	var startOfDay: Date? {
		return Calendar.current.date(from: Calendar.current.dateComponents([.day, .month, .year], from: self))
	}

	var endOfDay: Date? {
		return Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: self)
	}

	var startOfWeek: Date? {
		return Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
	}

	var endOfWeek: Date? {
		return Calendar.current.date(byAdding: .day, value: 7, to: self.startOfWeek!)
	}

	func isInMonth(of date: Date) -> Bool {
		let selfMonth = Calendar.current.dateComponents([.month, .year], from: self)
		let dateMonth = Calendar.current.dateComponents([.month, .year], from: date)
		return selfMonth == dateMonth
	}
}
