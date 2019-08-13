//
//  CalendarWeek.swift
//  MoJob
//
//  Created by Martin Schneider on 11.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class CalendarWeek: NSView {

	@IBOutlet var contentView: NSView!
	@IBOutlet weak var week: NSTextField!
	@IBOutlet weak var time: NSTextField!

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)

		commonInit()
	}

	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)

		commonInit()
	}

	private func commonInit() {
		Bundle.main.loadNibNamed("CalendarWeek", owner: self, topLevelObjects: nil)
		addSubview(contentView)

		contentView.frame = self.bounds
		contentView.autoresizingMask = [.width, .height]
		contentView.wantsLayer = true
		contentView.layer?.backgroundColor = NSColor.white.cgColor

		addConstraints([
			NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 65)
		])
	}

}
