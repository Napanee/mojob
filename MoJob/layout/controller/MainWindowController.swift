//
//  MainWindowController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {

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
		self.daySplitViewController = daySplitViewController

		let contentSplitViewController = initContentSplitViewController(with: "jobList", and: daySplitViewController)
		let mainSplitViewController = initMainSplitViewController(with: contentSplitViewController)
		let appViewController = initAppViewController(with: mainSplitViewController)

		contentViewController = appViewController
	}

	override func mouseDown(with event: NSEvent) {
		window?.makeFirstResponder(nil)
	}

	func windowShouldClose(_ sender: NSWindow) -> Bool {
		NSApp.setActivationPolicy(.prohibited)

		return true
	}

	func initContentSplitViewController(with primaryChild: String, and secondaryChild: SplitViewController) -> ContentSplitViewController {
		if let contentSplitViewController = contentSplitViewController {
			if (primaryChild == "calendar") {
				contentSplitViewController.showCalendar()
			} else {
				contentSplitViewController.showJobList()
			}

			return contentSplitViewController
		}

		let contentSplitViewController = ContentSplitViewController() // Calendar || JobList
		if (primaryChild == "calendar") {
			contentSplitViewController.showCalendar()
		} else {
			contentSplitViewController.showJobList()
		}
		contentSplitViewController.addChild(secondaryChild)

		self.contentSplitViewController = contentSplitViewController

		return contentSplitViewController
	}

	func initMainSplitViewController(with child: SplitViewController) -> MainSplitViewController {
		if let mainSplitViewController = mainSplitViewController {
			return mainSplitViewController
		}

		let mainSplitViewController = MainSplitViewController() // Content + CurrentTracking
		mainSplitViewController.addChild(child)

		if CoreDataHelper.currentTracking != nil {
			let trackingViewController = TrackingViewController(nibName: .trackingViewControllerNib, bundle: nil)
			mainSplitViewController.addChild(trackingViewController)
		}

		self.mainSplitViewController = mainSplitViewController

		return mainSplitViewController
	}

	func initAppViewController(with child: SplitViewController) -> SplitViewController {
		let appViewController = SplitViewController() // App Views => Navigation | MainContent
		appViewController.identifier = NSUserInterfaceItemIdentifier("AppViews")
		appViewController.addChild(NavigationController(nibName: .navigationControllerNib, bundle: nil))
		appViewController.addChild(child)

		return appViewController
	}

	func showJobList() {
		let contentSplitViewController = initContentSplitViewController(with: "jobList", and: daySplitViewController!)

		if let contentViewController = contentViewController as? SplitViewController, mainSplitViewController == nil {
			let mainSplitViewController = initMainSplitViewController(with: contentSplitViewController)
			contentViewController.replaceView(at: 1, with: mainSplitViewController)
		}
	}

	func showCalendar() {
		let contentSplitViewController = initContentSplitViewController(with: "calendar", and: daySplitViewController!)

		if let contentViewController = contentViewController as? SplitViewController, mainSplitViewController == nil {
			let mainSplitViewController = initMainSplitViewController(with: contentSplitViewController)
			contentViewController.replaceView(at: 1, with: mainSplitViewController)
		}
	}

	func showSettings() {
		let settings = SettingsViewController(nibName: .settingsControllerNib, bundle: nil)
		if let contentViewController = contentViewController as? SplitViewController {
			contentViewController.replaceView(at: 1, with: settings)
		}

		mainSplitViewController = nil
	}

}
