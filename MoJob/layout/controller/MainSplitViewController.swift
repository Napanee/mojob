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

	func toggleTracking() {
		NSAnimationContext.runAnimationGroup({context in
			context.duration = 0.25
			context.allowsImplicitAnimation = true

			if let height = NSApp.mainWindow?.contentView?.frame.height {
				splitView.setPosition(height - 238, ofDividerAt: 0)
			}
		}, completionHandler: nil)
	}

	func showTracking() {
		let trackingViewController = TrackingViewController(nibName: .trackingViewControllerNib, bundle: nil)
		let splitViewItem = NSSplitViewItem(viewController: trackingViewController)

		insertSplitViewItem(splitViewItem, at: 1)
	}

	func removeTracking() {
		if let index = children.firstIndex(where: { $0.isKind(of: TrackingViewController.self) }) {
			removeChild(at: index)
		}
	}

}
