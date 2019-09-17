//
//  NavigationController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class NavigationController: NSViewController {

	var window: NSWindow!
	@IBOutlet weak var timeTrackerButton: NSButton!
	@IBOutlet weak var calendarButton: NSButton!
	@IBOutlet weak var statsButton: NSButton!
	@IBOutlet weak var settingsButton: NSButton!
	
	@IBAction func trackerView(_ sender: NSButton) {
		(NSApp.mainWindow?.windowController as? MainWindowController)?.showJobList()

		sender.isEnabled = false
		sender.image = NSImage(named: .timerActiveImage)
		calendarButton.isEnabled = true
		calendarButton.image = NSImage(named: .calendarImage)
		statsButton.isEnabled = true
		statsButton.image = NSImage(named: .settingsImage)
		settingsButton.isEnabled = true
		settingsButton.image = NSImage(named: .settingsImage)
	}

	@IBAction func calendarView(_ sender: NSButton) {
		(NSApp.mainWindow?.windowController as? MainWindowController)?.showCalendar()

		sender.isEnabled = false
		sender.image = NSImage(named: .calendarActiveImage)
		timeTrackerButton.isEnabled = true
		timeTrackerButton.image = NSImage(named: .timerImage)
		statsButton.isEnabled = true
		statsButton.image = NSImage(named: .settingsImage)
		settingsButton.isEnabled = true
		settingsButton.image = NSImage(named: .settingsImage)
	}

	@IBAction func statsView(_ sender: NSButton) {
		(NSApp.mainWindow?.windowController as? MainWindowController)?.showStats()

		sender.isEnabled = false
		sender.image = NSImage(named: .settingsActiveImage)
		timeTrackerButton.isEnabled = true
		timeTrackerButton.image = NSImage(named: .timerImage)
		calendarButton.isEnabled = true
		calendarButton.image = NSImage(named: .calendarImage)
		settingsButton.isEnabled = true
		settingsButton.image = NSImage(named: .settingsImage)
	}

	@IBAction func settingsView(_ sender: NSButton) {
		(NSApp.mainWindow?.windowController as? MainWindowController)?.showSettings()

		sender.isEnabled = false
		sender.image = NSImage(named: .settingsActiveImage)
		timeTrackerButton.isEnabled = true
		timeTrackerButton.image = NSImage(named: .timerImage)
		calendarButton.isEnabled = true
		calendarButton.image = NSImage(named: .calendarImage)
		statsButton.isEnabled = true
		statsButton.image = NSImage(named: .settingsImage)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
		guard let window = appDelegate.window else { return }

		self.window = window

		(timeTrackerButton.cell as? NSButtonCell)?.imageDimsWhenDisabled = false
		(calendarButton.cell as? NSButtonCell)?.imageDimsWhenDisabled = false
		(settingsButton.cell as? NSButtonCell)?.imageDimsWhenDisabled = false
	}

	func replaceContent(with content: NSViewController) {
		guard let contentViewController = window.contentViewController else { return }

		NSAnimationContext.runAnimationGroup({ (context) -> Void in
			context.duration = 0.3
			contentViewController.children[1].view.animator().alphaValue = 0
		}, completionHandler: { () -> Void in
			content.view.alphaValue = 0
			contentViewController.removeChild(at: 1)
			contentViewController.insertChild(content, at: 1)
			contentViewController.children[1].view.animator().alphaValue = 1
		})
	}

}
