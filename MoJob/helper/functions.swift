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
		return dateFormatter.string(from: self)
	}

	var day: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "dd"
		return dateFormatter.string(from: self)
	}

	var year: String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "YYYY"
		return dateFormatter.string(from: self)
	}
}
