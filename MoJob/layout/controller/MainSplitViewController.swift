//
//  MainSplitViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 25.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class MainSplitViewController: SplitViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		splitView.isVertical = false
		identifier = NSUserInterfaceItemIdentifier("ContentSplitView+CurrentTracking")
	}

	func showSettings() {
		let settings = SettingsViewController(nibName: .settingsControllerNib, bundle: nil)
		replaceView(at: 0, with: settings)

		identifier = NSUserInterfaceItemIdentifier("Settings")
	}

}
