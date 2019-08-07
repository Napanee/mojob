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
	@IBOutlet weak var settingsButton: NSButton!
	
	@IBAction func trackerView(_ sender: NSButton) {
		let tracking = TrackingSplitViewController()

		replaceContent(with: tracking)

		sender.isEnabled = false
		sender.image = NSImage(named: "timer-active")
		settingsButton.isEnabled = true
		settingsButton.image = NSImage(named: "settings")
	}

	@IBAction func settingsView(_ sender: NSButton) {
		let settings = SettingsViewController()

		replaceContent(with: settings)

		sender.isEnabled = false
		sender.image = NSImage(named: "settings-active")
		timeTrackerButton.isEnabled = true
		timeTrackerButton.image = NSImage(named: "timer")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()

		guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
		guard let window = appDelegate.window else { return }

		self.window = window

		(timeTrackerButton.cell as? NSButtonCell)?.imageDimsWhenDisabled = false
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
