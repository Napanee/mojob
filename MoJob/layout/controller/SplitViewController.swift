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

		if let identifier = identifier {
			splitView.autosaveName = "\(identifier)+Divider"
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

	func collapsePanel(_ number: Int = 0){
		guard number < self.splitViewItems.count else {
			return
		}
		let panel = self.splitViewItems[number]

		if panel.isCollapsed {
			panel.animator().isCollapsed = false
		} else {
			panel.animator().isCollapsed = true
		}
	}

	func replaceView(at index: Int, with viewController: NSViewController) {
		NSAnimationContext.runAnimationGroup({ (context) -> Void in
			context.duration = 0.3
			children[index].view.animator().alphaValue = 0
		}, completionHandler: { () -> Void in
			viewController.view.alphaValue = 0
			self.removeChild(at: index)
			self.insertChild(viewController, at: index)
			self.children[index].view.animator().alphaValue = 1
		})
	}

}
