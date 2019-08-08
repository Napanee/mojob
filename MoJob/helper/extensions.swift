//
//  extensions.swift
//  MoJob
//
//  Created by Martin Schneider on 01.04.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import AppKit
import Foundation


extension NSImage.Name {
	static let checked = NSImage.Name("checked")
	static let delete = NSImage.Name("delete")
	static let login = NSImage.Name("login")
	static let play = NSImage.Name("play")
	static let reload = NSImage.Name("reload")
	static let settingsActive = NSImage.Name("settings-active")
	static let settings = NSImage.Name("settings")
	static let starEmpty = NSImage.Name("star-empty")
	static let starFilled = NSImage.Name("star-filled")
	static let stop = NSImage.Name("stop")
	static let syncError = NSImage.Name("sync-error")
	static let syncPending = NSImage.Name("sync-pending")
	static let syncSuccess = NSImage.Name("sync-success")
	static let timerActive = NSImage.Name("timer-active")
	static let timer = NSImage.Name("timer")
	static let unchecked = NSImage.Name("unchecked")
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
		return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)
	}

	var endOfDay: Date? {
		return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self)
	}
}
