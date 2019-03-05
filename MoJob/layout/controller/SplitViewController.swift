//
//  SplitViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class SplitViewController: NSSplitViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		if (splitViewItems.count == 3) {
			splitView.autosaveName = "save_divider"

			let left = splitView.subviews[1]
			let right = splitView.subviews[2]

			left.addConstraint(NSLayoutConstraint(item: left, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .width, multiplier: 1, constant: 300))
			right.addConstraint(NSLayoutConstraint(item: right, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .width, multiplier: 1, constant: 400))
		}
	}

	override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
		return NSRect(x: drawnRect.minX - 2, y: 0, width: drawnRect.width + 4, height: drawnRect.height)
	}

	func showTracking() {
		if let jobListViewControllerIndex = splitViewItems.firstIndex(where: { $0.viewController is JobListController }) {
			let trackingViewController = TrackingViewController(nibName: nibNames.TrackingViewController, bundle: nil)
			let splitViewItem = splitViewItems[jobListViewControllerIndex]

			removeSplitViewItem(splitViewItem)
			insertChild(trackingViewController, at: jobListViewControllerIndex)
		}
	}

}
