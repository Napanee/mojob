//
//  DoubleRightButton.swift
//  MoJob
//
//  Created by Martin Schneider on 30.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class DoubleRightButton: NSButton {

	let colorForegroundDefault = NSColor.controlTextColor

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		colorForegroundDefault.setStroke()

		var circlePath = NSBezierPath(ovalIn: NSRect(x: 0.25, y: 0.25, width: 21.5, height: 21.5))
		circlePath.lineWidth = 0.5

		if (isHighlighted) {
			circlePath = NSBezierPath(ovalIn: NSRect(x: 0.5, y: 0.5, width: 21, height: 21))
			circlePath.lineWidth = 1.0
		}

		circlePath.stroke()

		let arrow2Path = NSBezierPath()
		arrow2Path.move(to: NSPoint(x: 11.07, y: 7))
		arrow2Path.line(to: NSPoint(x: 15, y: 11))
		arrow2Path.line(to: NSPoint(x: 11.07, y: 15))
		arrow2Path.lineWidth = 0.5
		if (isHighlighted) {
			arrow2Path.lineWidth = 1.0
		}
		arrow2Path.lineCapStyle = .round
		arrow2Path.lineJoinStyle = .round
		arrow2Path.stroke()

		let arrow1Path = NSBezierPath()
		arrow1Path.move(to: NSPoint(x: 7.25, y: 7))
		arrow1Path.line(to: NSPoint(x: 11.18, y: 11))
		arrow1Path.line(to: NSPoint(x: 7.25, y: 15))
		arrow1Path.lineWidth = 0.5
		if (isHighlighted) {
			arrow1Path.lineWidth = 1.0
		}
		arrow1Path.lineCapStyle = .round
		arrow1Path.lineJoinStyle = .round
		arrow1Path.stroke()
	}

}
