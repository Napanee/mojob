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
