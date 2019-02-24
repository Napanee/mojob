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
		let dayTrackings = DayTrackingsController(nibName: nibNames.DayTrackingsController, bundle: nil)
		splitViewController.addChild(navigation)
		splitViewController.addChild(jobList)
		splitViewController.addChild(dayTrackings)

		contentViewController = splitViewController
	}

}
