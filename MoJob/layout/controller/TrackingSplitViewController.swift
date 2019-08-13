//
//  TrackingSplitViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 04.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingSplitViewController: EditorSplitViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		var leftController: NSViewController

		if let _ = CoreDataHelper.shared.currentTracking {
			leftController = TrackingViewController(nibName: .trackingViewControllerNib, bundle: nil)
		} else {
			leftController = JobListController(nibName: .jobListControllerNib, bundle: nil)
		}

		let lessConstraint = NSLayoutConstraint(item: leftController.view, attribute: .width, relatedBy: .lessThanOrEqual, toItem: leftController.view.superview, attribute: .width, multiplier: 1, constant: 600)
		let greaterConstraint = NSLayoutConstraint(item: leftController.view, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: leftController.view.superview, attribute: .width, multiplier: 1, constant: 350)

		leftController.view.addConstraints([lessConstraint, greaterConstraint])

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

		addChild(leftController)
		addChild(verticalSplitViewController)
	}

	func showTracking() {
		if let jobListViewControllerIndex = splitViewItems.firstIndex(where: { $0.viewController is JobListController }) {
			let trackingViewController = TrackingViewController(nibName: .trackingViewControllerNib, bundle: nil)

			NSAnimationContext.runAnimationGroup({ (context) -> Void in
				context.duration = 0.3
				children[jobListViewControllerIndex].view.animator().alphaValue = 0
			}, completionHandler: { () -> Void in
				trackingViewController.view.alphaValue = 0
				self.removeChild(at: jobListViewControllerIndex)
				self.insertChild(trackingViewController, at: jobListViewControllerIndex)
				self.children[jobListViewControllerIndex].view.animator().alphaValue = 1
			})
		}
	}

	func showJobList() {
		if let trackingViewControllerIndex = splitViewItems.firstIndex(where: { $0.viewController is TrackingViewController }) {
			let jobListViewController = JobListController(nibName: .jobListControllerNib, bundle: nil)

			jobListViewController.view.addConstraint(NSLayoutConstraint(item: jobListViewController.view, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: jobListViewController.view.superview, attribute: .width, multiplier: 1, constant: 450))

			NSAnimationContext.runAnimationGroup({ (context) -> Void in
				context.duration = 0.3
				children[trackingViewControllerIndex].view.animator().alphaValue = 0
			}, completionHandler: { () -> Void in
				jobListViewController.view.alphaValue = 0
				self.removeChild(at: trackingViewControllerIndex)
				self.insertChild(jobListViewController, at: trackingViewControllerIndex)
				self.children[trackingViewControllerIndex].view.animator().alphaValue = 1
			})
		}
	}

}
