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

	weak var appDelegate = NSApplication.shared.delegate as? AppDelegate

	var currentContentViewController: NSViewController? {
		get {
			return contentViewController?.children[1]
		}
	}

	override func windowDidLoad() {
		super.windowDidLoad()

		appDelegate?.window = window
		window?.backgroundColor = NSColor.controlBackgroundColor

		let splitViewController = SplitViewController()
		let navigation = NavigationController(nibName: .navigationControllerNib, bundle: nil)
		let trackingSplitViewController = TrackingSplitViewController()

		splitViewController.addChild(navigation)
		splitViewController.addChild(trackingSplitViewController)

		contentViewController = splitViewController
	}

	override func mouseDown(with event: NSEvent) {
		window?.makeFirstResponder(nil)
	}

}
