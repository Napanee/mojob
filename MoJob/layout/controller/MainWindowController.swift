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
	}

}
