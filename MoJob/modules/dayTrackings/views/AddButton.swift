//
//  AddButton.swift
//  MoJob
//
//  Created by Martin Schneider on 10.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class AddButton: NSView {

	@IBOutlet var contentView: NSView!
	var constraint: NSLayoutConstraint?
	var from: Date = Date()
	var until: Date = Date()

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)

		commonInit()
	}

	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)

		commonInit()
	}

	private func commonInit() {
		Bundle.main.loadNibNamed("AddButton", owner: self, topLevelObjects: nil)
		addSubview(contentView)

		contentView.frame = self.bounds
		contentView.autoresizingMask = [.width, .height]
		contentView.wantsLayer = true
		contentView.layer?.backgroundColor = NSColor(red: 0.961, green: 0.961, blue: 0.961, alpha: 1).cgColor

		addConstraints([
			NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
		])
	}

	@IBAction func addTracking(_ sender: NSButton) {
		if
			let daySplitViewController = (NSApp.mainWindow?.windowController as? MainWindowController)?.daySplitViewController,
			let tracking = CoreDataHelper.createTracking(in: CoreDataHelper.backgroundContext)
		{
			tracking.date_start = from
			tracking.date_end = until

			let editor = EditorController(nibName: .editorControllerNib, bundle: nil)
			editor.tracking = tracking
			let splitViewItem = NSSplitViewItem(viewController: editor)
			splitViewItem.isCollapsed = true

			daySplitViewController.insertSplitViewItem(splitViewItem, at: 0)
			daySplitViewController.collapsePanel(0)
		}
	}

}
