//
//  AddButton.swift
//  MoJob
//
//  Created by Martin Schneider on 10.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class AddButton: NSButton {

	var constraint: NSLayoutConstraint?

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)

		commonInit()
	}

	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)

		commonInit()
	}

	private func commonInit() {
		title = "add"
		isBordered = false
		wantsLayer = true
		layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
		translatesAutoresizingMaskIntoConstraints = false

		constraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30)
		addConstraint(constraint!)
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
	}

}
