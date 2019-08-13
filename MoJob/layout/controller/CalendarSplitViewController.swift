//
//  CalendarSplitViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 11.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class CalendarSplitViewController: EditorSplitViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		let verticalSplitViewController = NSSplitViewController()
		verticalSplitViewController.view.addConstraint(
			NSLayoutConstraint(
				item: verticalSplitViewController.view, attribute: .width, relatedBy: .lessThanOrEqual,
				toItem: verticalSplitViewController.view.superview, attribute: .width, multiplier: 1, constant: 515
			)
		)
		let dayTrackings = DayTrackingsController(nibName: .dayTrackingsControllerNib, bundle: nil)

		verticalSplitViewController.splitView.isVertical = false
		verticalSplitViewController.addChild(dayTrackings)

		addChild(CalendarController(nibName: .calendarControllerNib, bundle: nil))
		addChild(verticalSplitViewController)
	}

}
