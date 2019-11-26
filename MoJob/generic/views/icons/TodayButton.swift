//
//  TodayButton.swift
//  MoJob
//
//  Created by Martin Schneider on 30.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TodayButton: NSButton {

	let colorForegroundDefault = NSColor.controlTextColor

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		colorForegroundDefault.setStroke()
		var rectanglePath = NSBezierPath(roundedRect: NSRect(x: 0.25, y: 0.25, width: 79.5, height: 31.5), xRadius: 15.75, yRadius: 15.75)
		rectanglePath.lineWidth = 0.5

		if (isHighlighted) {
			rectanglePath = NSBezierPath(roundedRect: NSRect(x: 0.5, y: 0.5, width: 79, height: 31), xRadius: 16, yRadius: 16)
			rectanglePath.lineWidth = 1.0
		}

		rectanglePath.lineJoinStyle = .round
		rectanglePath.stroke()
	}

}
