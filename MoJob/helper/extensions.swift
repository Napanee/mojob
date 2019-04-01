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
	static let delete = NSImage.Name("delete")
	static let play = NSImage.Name("play")
	static let stop = NSImage.Name("stop")
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

	var startOfDay: Date? {
		return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)
	}

	var endOfDay: Date? {
		return Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self)
	}
}
