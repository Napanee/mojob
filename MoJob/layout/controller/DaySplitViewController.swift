//
//  DaySplitViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 25.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class DaySplitViewController: SplitViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		splitView.isVertical = false
		identifier = NSUserInterfaceItemIdentifier("Editor+Day")

		let dayTrackingsController = DayTrackingsController(nibName: .dayTrackingsControllerNib, bundle: nil)
		addChild(dayTrackingsController)
	}

}
