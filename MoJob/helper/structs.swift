//
//  structs.swift
//  MoJob
//
//  Created by Martin Schneider on 01.04.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Foundation


struct BaseData {
	var from: Date
	var until: Date
}

struct TempTracking {
	var tracking: Tracking?
	var job: Job?
	var task: Task?
	var activity: Activity?
	var custom_job: String?
	var comment: String?
	var date_start: Date
	var date_end: Date?

	var isValid: Bool {
		get {
			return activity != nil &&
			(date_end ?? Date()).timeIntervalSince(date_start) > 60 &&
			(job != nil || custom_job != nil)
		}
	}

	init(customJob: String) {
		self.custom_job = customJob
		self.date_start = Calendar.current.date(bySetting: .second, value: 0, of: Date())!
	}

	init(job: Job) {
		self.job = job
		self.date_start = Calendar.current.date(bySetting: .second, value: 0, of: Date())!
	}

	init(start: Date, end: Date) {
		self.date_start = start
		self.date_end = end
	}

	init(tracking: Tracking) {
		self.job = tracking.job
		self.task = tracking.task
		self.activity = tracking.activity
		self.custom_job = tracking.custom_job
		self.comment = tracking.comment
		self.date_start = tracking.date_start ?? Calendar.current.date(bySetting: .second, value: 0, of: Date())!
		self.date_end = tracking.date_end
	}
}
