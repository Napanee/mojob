//
//  ContentSplitViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 25.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class ContentSplitViewController: SplitViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		splitView.isVertical = true
		identifier = NSUserInterfaceItemIdentifier("Calendar|JobList+DaySplitView")
	}

	func showCalendar() {
		let calendar = CalendarController(nibName: .calendarControllerNib, bundle: nil)

		if (children.count > 1) {
			replaceView(at: 0, with: calendar)
		} else {
			addChild(calendar)
		}
	}

	func showJobList() {
		let jobList = JobListController(nibName: .jobListControllerNib, bundle: nil)

		if (children.count > 1) {
			replaceView(at: 0, with: jobList)
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "calendar:changedDate"), object: ["day": Date().startOfDay as Any, "job": nil])
		} else {
			addChild(jobList)
		}
	}

}
