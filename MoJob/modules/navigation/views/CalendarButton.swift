//
//  CalendarButton.swift
//  MoJob
//
//  Created by Martin Schneider on 24.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class CalendarButton: BaseButton {

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		colorBackgroundDefault.setFill()
		colorForegroundDefault.setStroke()

		if (!isEnabled) {
			colorBackgroundInverted.setFill()
		}

		let rectanglePath = NSBezierPath(roundedRect: NSRect(x: 0.5, y: 0.5, width: 29, height: 29), xRadius: 1, yRadius: 1)
		rectanglePath.lineWidth = lineWidth
		rectanglePath.fill()
		rectanglePath.stroke()

		if (!isEnabled) {
			colorForegroundInverted.setFill()
			colorForegroundInverted.setStroke()
		} else {
			colorForegroundDefault.setFill()
			colorForegroundDefault.setStroke()
		}

		let pointTopRightPath = NSBezierPath(rect: NSRect(x: 21.5, y: 3.5, width: 3, height: 3))
		pointTopRightPath.lineWidth = lineWidth
		pointTopRightPath.lineJoinStyle = .round
		pointTopRightPath.stroke()

		let pointTopLeftPath = NSBezierPath(rect: NSRect(x: 5.5, y: 3.5, width: 3, height: 3))
		pointTopLeftPath.lineWidth = lineWidth
		pointTopLeftPath.lineJoinStyle = .round
		pointTopLeftPath.stroke()

		let horizontalLine = NSBezierPath()
		horizontalLine.move(to: NSPoint(x: 0, y: 9))
		horizontalLine.line(to: NSPoint(x: 30, y: 9))
		horizontalLine.lineWidth = lineWidth
		horizontalLine.stroke()

		let point1Path = NSBezierPath(roundedRect: NSRect(x: 4, y: 13, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point1Path.fill()
		let point2Path = NSBezierPath(roundedRect: NSRect(x: 10, y: 13, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point2Path.fill()
		let point3Path = NSBezierPath(roundedRect: NSRect(x: 16, y: 13, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point3Path.fill()
		let point4Path = NSBezierPath(roundedRect: NSRect(x: 22, y: 13, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point4Path.fill()
		let point5Path = NSBezierPath(roundedRect: NSRect(x: 4, y: 18, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point5Path.fill()
		let point6Path = NSBezierPath(roundedRect: NSRect(x: 10, y: 18, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point6Path.fill()
		let point7Path = NSBezierPath(roundedRect: NSRect(x: 16, y: 18, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point7Path.fill()
		let point8Path = NSBezierPath(roundedRect: NSRect(x: 22, y: 18, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point8Path.fill()
		let point9Path = NSBezierPath(roundedRect: NSRect(x: 4, y: 23, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point9Path.fill()
		let point10Path = NSBezierPath(roundedRect: NSRect(x: 10, y: 23, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point10Path.fill()
		let point11Path = NSBezierPath(roundedRect: NSRect(x: 16, y: 23, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point11Path.fill()
		let point12Path = NSBezierPath(roundedRect: NSRect(x: 22, y: 23, width: 4, height: 3), xRadius: 0.5, yRadius: 0.5)
		point12Path.fill()
	}

}
