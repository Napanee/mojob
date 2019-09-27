//
//  NavigationController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class NavigationController: NSViewController {

	@IBOutlet weak var timeTrackerButton: NSButton!
	@IBOutlet weak var calendarButton: NSButton!
	@IBOutlet weak var statsButton: NSButton!
	@IBOutlet weak var settingsButton: NSButton!

	var window: NSWindow!
	var buttons: [NSButton] = []

	override func viewDidLoad() {
		super.viewDidLoad()

		guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
		guard let window = appDelegate.window else { return }

		self.window = window

		buttons = [
			timeTrackerButton,
			calendarButton,
			settingsButton,
			statsButton
		]

		buttons.forEach({
			($0.cell as? NSButtonCell)?.imageDimsWhenDisabled = false
		})
	}

	@IBAction func button(_ sender: NSButton) {
		guard let mainWindowController = (NSApp.mainWindow?.windowController as? MainWindowController) else { return }

		buttons.forEach({ $0.isEnabled = true })
		sender.isEnabled = false

		if (sender.isEqual(timeTrackerButton.self)) {
			mainWindowController.showJobList()
		} else if (sender.isEqual(calendarButton.self)) {
			mainWindowController.showCalendar()
		} else if (sender.isEqual(statsButton.self)) {
			mainWindowController.showStats()
		} else if (sender.isEqual(settingsButton.self)) {
			mainWindowController.showSettings()
		}
	}

}
