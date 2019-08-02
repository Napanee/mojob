//
//  SplitViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


class SplitViewController: NSSplitViewController {

	var prevWidth: CGFloat?

	override func viewDidLoad() {
		super.viewDidLoad()

		if (splitViewItems.count == 3) {
			splitView.autosaveName = "save_divider"
		}
	}

	override func removeSplitViewItem(_ splitViewItem: NSSplitViewItem) {
		super.removeSplitViewItem(splitViewItem)

		prevWidth = splitViewItem.viewController.view.bounds.width
	}

	override func insertChild(_ childViewController: NSViewController, at index: Int) {
		if let prevWidth = prevWidth {
			childViewController.view.frame.size.width = prevWidth
			self.prevWidth = nil
		}

		super.insertChild(childViewController, at: index)
	}

	override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
		return NSRect(x: drawnRect.minX - 2, y: 0, width: drawnRect.width + 4, height: drawnRect.height)
	}

	func showTracking() {
		if let jobListViewControllerIndex = splitViewItems.firstIndex(where: { $0.viewController is JobListController }) {
			let trackingViewController = TrackingViewController(nibName: nibNames.TrackingViewController, bundle: nil)
			let splitViewItem = splitViewItems[jobListViewControllerIndex]

			trackingViewController.view.addConstraint(NSLayoutConstraint(item: trackingViewController.view, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: trackingViewController.view.superview, attribute: .width, multiplier: 1, constant: 300))

			NSAnimationContext.runAnimationGroup({ (_) -> Void in
				splitViewItem.viewController.view.animator().alphaValue = 0
			}, completionHandler: { () -> Void in
				trackingViewController.view.alphaValue = 0
				self.removeSplitViewItem(splitViewItem)
				self.insertChild(trackingViewController, at: jobListViewControllerIndex)
				trackingViewController.view.animator().alphaValue = 1.0
			})
		}
	}

	func showEditor(with tracking: TempTracking) {
		if let verticalSplitViewController = splitViewItems.first(where: { $0.viewController.isKind(of: NSSplitViewController.self) })?.viewController as? NSSplitViewController {
			let editorViewController = EditorController(nibName: nibNames.EditorController, bundle: nil)

			if let currentEditorIndex = verticalSplitViewController.splitViewItems.firstIndex(where: { $0.viewController.isKind(of: EditorController.self) }) {
				verticalSplitViewController.splitViewItems.remove(at: currentEditorIndex)
			}

			editorViewController.tempTracking = tracking

			verticalSplitViewController.insertChild(editorViewController, at: 0)
		}
	}

	func showEditor(with tracking: Tracking) {
		if let verticalSplitViewController = splitViewItems.first(where: { $0.viewController.isKind(of: NSSplitViewController.self) })?.viewController as? NSSplitViewController {
			let editorViewController = EditorController(nibName: nibNames.EditorController, bundle: nil)

			if let currentEditorIndex = verticalSplitViewController.splitViewItems.firstIndex(where: { $0.viewController.isKind(of: EditorController.self) }) {
				verticalSplitViewController.splitViewItems.remove(at: currentEditorIndex)
			}

			editorViewController.tracking = tracking

			verticalSplitViewController.insertChild(editorViewController, at: 0)
		}
	}

	func showJobList() {
		if let trackingViewControllerIndex = splitViewItems.firstIndex(where: { $0.viewController is TrackingViewController }) {
			let jobListViewControllerIndex = JobListController(nibName: nibNames.JobListController, bundle: nil)
			let splitViewItem = splitViewItems[trackingViewControllerIndex]

			jobListViewControllerIndex.view.addConstraint(NSLayoutConstraint(item: jobListViewControllerIndex.view, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: jobListViewControllerIndex.view.superview, attribute: .width, multiplier: 1, constant: 300))

			NSAnimationContext.runAnimationGroup({ (_) -> Void in
				splitViewItem.viewController.view.animator().alphaValue = 0
			}, completionHandler: { () -> Void in
				jobListViewControllerIndex.view.alphaValue = 0
				self.removeSplitViewItem(splitViewItem)
				self.insertChild(jobListViewControllerIndex, at: trackingViewControllerIndex)
				jobListViewControllerIndex.view.animator().alphaValue = 1.0
			})
		}
	}

}
