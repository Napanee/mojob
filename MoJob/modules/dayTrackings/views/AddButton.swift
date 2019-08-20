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
		if let appDelegate = NSApp.delegate as? AppDelegate, let mainWindowController = appDelegate.mainWindowController, let contentViewController = mainWindowController.currentContentViewController as? EditorSplitViewController {
			if let tracking = CoreDataHelper.createTracking(in: CoreDataHelper.backgroundContext) {
				tracking.date_start = from
				tracking.date_end = until

				contentViewController.showEditor(with: tracking)
			}
		}
	}

}
