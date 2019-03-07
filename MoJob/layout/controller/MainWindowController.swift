//
//  MainWindowController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

	override var windowNibName: NSNib.Name? { return "MainWindowController" }
	override var owner: AnyObject? { return self }

	let appDelegate = NSApplication.shared.delegate as! AppDelegate

	override func windowDidLoad() {
		super.windowDidLoad()

		appDelegate.window = window

		let splitViewController = SplitViewController()
		let navigation = NavigationController(nibName: nibNames.NavigationController, bundle: nil)
		let jobList = JobListController(nibName: nibNames.JobListController, bundle: nil)
		jobList.view.addConstraint(NSLayoutConstraint(item: jobList.view, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: jobList.view.superview, attribute: .width, multiplier: 1, constant: 300))
		let dayTrackings = DayTrackingsController(nibName: nibNames.DayTrackingsController, bundle: nil)
		dayTrackings.view.addConstraint(NSLayoutConstraint(item: dayTrackings.view, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: dayTrackings.view.superview, attribute: .width, multiplier: 1, constant: 400))
		splitViewController.addChild(navigation)
		splitViewController.addChild(jobList)
		splitViewController.addChild(dayTrackings)

		contentViewController = splitViewController
	}

}
