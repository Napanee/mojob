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
	var MD5: String {
		let data = Data(self.utf8)
		let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
			var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
			CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
			return hash
		}
		return hash.map { String(format: "%02x", $0) }.joined()
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
