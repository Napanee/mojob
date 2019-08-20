//
//  EditorSplitViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 11.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class EditorSplitViewController: SplitViewController {

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

			let splitViewItem = NSSplitViewItem(viewController: editorViewController)
			splitViewItem.isCollapsed = true

			verticalSplitViewController.insertSplitViewItem(splitViewItem, at: 0)

			splitViewItem.animator().isCollapsed = false
		}
	}

}
