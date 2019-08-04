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
		contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

		addConstraints([
			NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
		])
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
	}

	@IBAction func addTracking(_ sender: NSButton) {
		if let appDelegate = NSApp.delegate as? AppDelegate, let mainWindowController = appDelegate.mainWindowController, let contentViewController = mainWindowController.currentContentViewController as? TrackingSplitViewController {
			let tracking = TempTracking(start: from, end: until)

			contentViewController.showEditor(with: tracking)
		}
	}

}
