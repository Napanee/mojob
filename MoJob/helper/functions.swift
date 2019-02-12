//
//  functions.swift
//  MoJob
//
//  Created by Martin Schneider on 11.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//


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
