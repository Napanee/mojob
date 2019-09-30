//
//  SingleRightButton.swift
//  MoJob
//
//  Created by Martin Schneider on 30.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class SingleRightButton: NSButton {

	let colorForegroundDefault = NSColor.controlTextColor

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		colorForegroundDefault.setStroke()

		if (!isEnabled) {
			colorForegroundDefault.withAlphaComponent(0.3).setStroke()
		}

		var circlePath = NSBezierPath(ovalIn: NSRect(x: 0.25, y: 0.25, width: 31.5, height: 31.5))
		circlePath.lineWidth = 0.5

		if (isHighlighted) {
			circlePath = NSBezierPath(ovalIn: NSRect(x: 0.5, y: 0.5, width: 31, height: 31))
			circlePath.lineWidth = 1.0
		}

		circlePath.stroke()

		let polygonPath = NSBezierPath()
		polygonPath.move(to: NSPoint(x: 13.75, y: 10))
		polygonPath.line(to: NSPoint(x: 19.75, y: 16))
		polygonPath.line(to: NSPoint(x: 13.75, y: 22))
		polygonPath.lineWidth = 0.5
		if (isHighlighted) {
			polygonPath.lineWidth = 1.0
		}
		polygonPath.lineCapStyle = .round
		polygonPath.lineJoinStyle = .round
		polygonPath.stroke()
	}

}
