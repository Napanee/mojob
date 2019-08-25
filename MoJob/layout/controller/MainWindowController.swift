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

	var mainSplitViewController: MainSplitViewController?
	var contentSplitViewController: ContentSplitViewController?
	var daySplitViewController: DaySplitViewController?

	override func windowDidLoad() {
		super.windowDidLoad()

		appDelegate?.window = window
		window?.backgroundColor = NSColor.controlBackgroundColor

		let daySplitViewController = DaySplitViewController() // Editor + Day
		let contentSplitViewController = ContentSplitViewController() // Calendar || JobList
		let mainSplitViewController = MainSplitViewController() // Content + CurrentTracking

		// App Views => Navigation | MainContent
		let appViewController = SplitViewController()
		appViewController.identifier = NSUserInterfaceItemIdentifier("AppViews")
		appViewController.addChild(NavigationController(nibName: .navigationControllerNib, bundle: nil))
		appViewController.addChild(mainSplitViewController)

		contentViewController = appViewController

		mainSplitViewController.addChild(contentSplitViewController)
		contentSplitViewController.showJobList()
		contentSplitViewController.addChild(daySplitViewController)

		self.mainSplitViewController = mainSplitViewController
		self.contentSplitViewController = contentSplitViewController
		self.daySplitViewController = daySplitViewController
	}

	override func mouseDown(with event: NSEvent) {
		window?.makeFirstResponder(nil)
	}

	func showContent() {
		contentSplitViewController = ContentSplitViewController()
		mainSplitViewController?.replaceView(at: 0, with: contentSplitViewController!)
	}

	func showJobList() {
		if let contentSplitViewController = contentSplitViewController {
			contentSplitViewController.showJobList()
		} else {
			showContent()
			contentSplitViewController?.showJobList()
			contentSplitViewController?.addChild(daySplitViewController!)
		}
	}

	func showCalendar() {
		if let contentSplitViewController = contentSplitViewController {
			contentSplitViewController.showCalendar()
		} else {
			showContent()
			contentSplitViewController?.showCalendar()
			contentSplitViewController?.addChild(daySplitViewController!)
		}
	}

	func showSettings() {
		mainSplitViewController?.showSettings()
		contentSplitViewController = nil
	}

}
