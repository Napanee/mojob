//
//  TrackingSplitViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 04.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingSplitViewController: SplitViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		var leftController: NSViewController

		if let _ = CoreDataHelper.shared.currentTracking {
			leftController = TrackingViewController(nibName: .trackingViewControllerNib, bundle: nil)
		} else {
			leftController = JobListController(nibName: .jobListControllerNib, bundle: nil)
		}

		leftController.view.addConstraint(
			NSLayoutConstraint(
				item: leftController.view,
				attribute: .width,
				relatedBy: .greaterThanOrEqual,
				toItem: leftController.view.superview,
				attribute: .width,
				multiplier: 1,
				constant: 300
			)
		)

		let verticalSplitViewController = NSSplitViewController()
		verticalSplitViewController.view.addConstraint(
			NSLayoutConstraint(
				item: verticalSplitViewController.view, attribute: .width, relatedBy: .greaterThanOrEqual,
				toItem: verticalSplitViewController.view.superview, attribute: .width, multiplier: 1, constant: 400
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

			trackingViewController.view.addConstraint(NSLayoutConstraint(item: trackingViewController.view, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: trackingViewController.view.superview, attribute: .width, multiplier: 1, constant: 300))

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

	func showEditor(with tracking: TempTracking) {
		if let verticalSplitViewController = splitViewItems.first(where: { $0.viewController.isKind(of: NSSplitViewController.self) })?.viewController as? NSSplitViewController {
			let editorViewController = EditorController(nibName: .editorControllerNib, bundle: nil)

			if let currentEditorIndex = verticalSplitViewController.splitViewItems.firstIndex(where: { $0.viewController.isKind(of: EditorController.self) }) {
				verticalSplitViewController.splitViewItems.remove(at: currentEditorIndex)
			}

			editorViewController.tempTracking = tracking

			verticalSplitViewController.insertChild(editorViewController, at: 0)
		}
	}

	func showEditor(with tracking: Tracking) {
		if let verticalSplitViewController = splitViewItems.first(where: { $0.viewController.isKind(of: NSSplitViewController.self) })?.viewController as? NSSplitViewController {
			let editorViewController = EditorController(nibName: .editorControllerNib, bundle: nil)

			if let currentEditorIndex = verticalSplitViewController.splitViewItems.firstIndex(where: { $0.viewController.isKind(of: EditorController.self) }) {
				verticalSplitViewController.splitViewItems.remove(at: currentEditorIndex)
			}

			editorViewController.sourceTracking = tracking

			verticalSplitViewController.insertChild(editorViewController, at: 0)
		}
	}

	func showJobList() {
		if let trackingViewControllerIndex = splitViewItems.firstIndex(where: { $0.viewController is TrackingViewController }) {
			let jobListViewController = JobListController(nibName: .jobListControllerNib, bundle: nil)

			jobListViewController.view.addConstraint(NSLayoutConstraint(item: jobListViewController.view, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: jobListViewController.view.superview, attribute: .width, multiplier: 1, constant: 300))

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
