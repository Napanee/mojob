//
//  QuickSelectWindowController.swift
//  MoJob
//
//  Created by Martin Schneider on 15.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


class QuickSelectWindowController: NSWindowController {

	override var windowNibName: NSNib.Name? { return "QuickSelectWindowController" }
	override var owner: AnyObject? { return self }

	weak var appDelegate = NSApplication.shared.delegate as? AppDelegate

	override func windowDidLoad() {
		super.windowDidLoad()

//		window?.backgroundColor = NSColor.red

		let navigation = NavigationController(nibName: nibNames.NavigationController, bundle: nil)

		contentViewController = navigation
	}

	@objc func cancel(_ sender: Any?) {
		window?.close()
		(NSApp.delegate as? AppDelegate)?.quickSelectWindowController = nil
	}

}
