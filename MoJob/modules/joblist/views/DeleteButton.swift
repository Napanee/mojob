//
//  DeleteButton.swift
//  MoJob
//
//  Created by Martin Schneider on 27.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class DeleteButton: NSButton {

	let colorForegroundDefault = NSColor.controlTextColor

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		colorForegroundDefault.setStroke()

		var circlePath = NSBezierPath(ovalIn: NSRect(x: 0.25, y: 0.25, width: 19.5, height: 19.5))
		circlePath.lineWidth = 0.5
		if (isHighlighted) {
			circlePath = NSBezierPath(ovalIn: NSRect(x: 0.5, y: 0.5, width: 19, height: 19))
			circlePath.lineWidth = 1.0
		}
		circlePath.stroke()

		let line2Path = NSBezierPath()
		line2Path.move(to: NSPoint(x: 6.5, y: 6.5))
		line2Path.line(to: NSPoint(x: 13.5, y: 13.5))
		line2Path.lineWidth = 0.5
		if (isHighlighted) {
			line2Path.lineWidth = 1.0
		}
		line2Path.lineCapStyle = .round
		line2Path.stroke()

		let line1Path = NSBezierPath()
		line1Path.move(to: NSPoint(x: 13.5, y: 6.5))
		line1Path.line(to: NSPoint(x: 6.5, y: 13.5))
		line1Path.lineWidth = 0.5
		if (isHighlighted) {
			line1Path.lineWidth = 1.0
		}
		line1Path.lineCapStyle = .round
		line1Path.stroke()

	}

}
