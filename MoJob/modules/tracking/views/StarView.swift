//
//  StarButton.swift
//  MoJob
//
//  Created by Martin Schneider on 24.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


@IBDesignable
class StarButton: NSButton {

	@IBInspectable var colorFill: NSColor = NSColor.red
	@IBInspectable var colorStroke: NSColor = NSColor.white

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		let starPath = NSBezierPath()
		starPath.move(to: NSPoint(x: 12.5, y: 1.5))
		starPath.line(to: NSPoint(x: 16.03, y: 8.64))
		starPath.line(to: NSPoint(x: 23.91, y: 9.79))
		starPath.line(to: NSPoint(x: 18.21, y: 15.35))
		starPath.line(to: NSPoint(x: 19.55, y: 23.21))
		starPath.line(to: NSPoint(x: 12.5, y: 19.5))
		starPath.line(to: NSPoint(x: 5.45, y: 23.21))
		starPath.line(to: NSPoint(x: 6.79, y: 15.35))
		starPath.line(to: NSPoint(x: 1.09, y: 9.79))
		starPath.line(to: NSPoint(x: 8.97, y: 8.64))
		starPath.close()

		if (state == .on) {
			colorFill.setFill()
			starPath.fill()
		}

		colorStroke.setStroke()
		starPath.lineWidth = 1.5
		starPath.lineJoinStyle = .round
		starPath.stroke()
	}

}
