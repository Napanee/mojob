//
//  functions.swift
//  MoJob
//
//  Created by Martin Schneider on 11.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Foundation


func secondsToHoursMinutesSeconds(sec: Int) -> String {
	let hours = sec / 3600
	let minutes = (sec % 3600) / 60
	let seconds = sec % 60
	var timeString = String()

	timeString += String(format: "%02d", hours) + ":"
	timeString += String(format: "%02d", minutes) + ":"
	timeString += String(format: "%02d", seconds)

	return timeString
}

extension String {
	var MD5: String? {
		let length = Int(CC_MD5_DIGEST_LENGTH)

		guard let data = self.data(using: String.Encoding.utf8) else { return nil }

		let hash = data.withUnsafeBytes { (bytes: UnsafePointer<Data>) -> [UInt8] in
			var hash: [UInt8] = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
			CC_MD5(bytes, CC_LONG(data.count), &hash)
			return hash
		}

		return (0..<length).map { String(format: "%02x", hash[$0]) }.joined()
	}
}

func maxDays(month: Int, year: Int) -> Int {
	let dateComponents = DateComponents(year: year, month: month)
	let calendar = Calendar.current
	let date = calendar.date(from: dateComponents)!

	let range = calendar.range(of: .day, in: .month, for: date)!
	let numDays = range.count

	return numDays
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
