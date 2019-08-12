//
//  ColorButton.swift
//  MoJob
//
//  Created by Martin Schneider on 03.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class ColorButton: NSButton {

	var color: NSColor!
	var key: String!

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)

		commonInit()
	}

	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)

		commonInit()
	}

	private func commonInit() {
		let constraint = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 15)

		addConstraint(constraint)
		wantsLayer = true
		layer?.cornerRadius = 2
		layer?.borderWidth = 1
		title = ""
		isBordered = false

		let trackingArea = NSTrackingArea(
			rect: bounds,
			options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited],
			owner: self,
			userInfo: nil
		)

		addTrackingArea(trackingArea)
	}

	override func draw(_ dirtyRect: NSRect) {
		layer?.backgroundColor = color.withAlphaComponent(0.3).cgColor
		layer?.borderColor = color.cgColor
	}

	override func mouseEntered(with event: NSEvent) {
		layer?.borderWidth = 2
		let animation = CABasicAnimation(keyPath: "borderWidth")
		animation.fromValue = 1
		animation.toValue = 2
		animation.duration = 0.2
		layer?.add(animation, forKey: "borderWidth")

		layer?.borderColor = NSColor.darkGray.cgColor
		let animation2 = CABasicAnimation(keyPath: "borderColor")
		animation2.fromValue = color.cgColor
		animation2.toValue = NSColor.darkGray.cgColor
		animation2.duration = 0.2
		layer?.add(animation2, forKey: "borderColor")

		layer?.backgroundColor = color.withAlphaComponent(0.8).cgColor
		let animation3 = CABasicAnimation(keyPath: "backgroundColor")
		animation3.fromValue = color.withAlphaComponent(0.3).cgColor
		animation3.toValue = color.withAlphaComponent(0.8).cgColor
		animation3.duration = 0.2
		layer?.add(animation3, forKey: "backgroundColor")
	}

	override func mouseExited(with event: NSEvent) {
		layer?.borderWidth = 1
		layer?.borderColor = color.cgColor
		layer?.backgroundColor = color.withAlphaComponent(0.3).cgColor
	}

}
