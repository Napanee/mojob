//
//  TrackerButton.swift
//  MoJob
//
//  Created by Martin Schneider on 24.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackerButton: BaseButton {

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		colorBackgroundDefault.setFill()
		colorForegroundDefault.setStroke()

		if (!isEnabled) {
			colorBackgroundInverted.setFill()
		}

		let circlePath = NSBezierPath(ovalIn: NSRect(x: lineWidth, y: lineWidth, width: bounds.width - lineWidth * 2, height: bounds.height - lineWidth * 2))
		circlePath.lineWidth = lineWidth
		circlePath.fill()
		circlePath.stroke()

		colorBackgroundInverted.setFill()

		if (!isEnabled) {
			colorBackgroundDefault.setFill()
			colorForegroundInverted.setStroke()
		}

		let pointleftPath = NSBezierPath(roundedRect: NSRect(x: 3, y: 14, width: 2, height: 2), xRadius: 0.5, yRadius: 0.5)
		pointleftPath.fill()
		let pointbottomPath = NSBezierPath(roundedRect: NSRect(x: 14, y: 25, width: 2, height: 2), xRadius: 0.5, yRadius: 0.5)
		pointbottomPath.fill()
		let pointrightPath = NSBezierPath(roundedRect: NSRect(x: 25, y: 14, width: 2, height: 2), xRadius: 0.5, yRadius: 0.5)
		pointrightPath.fill()
		let pointtopPath = NSBezierPath(roundedRect: NSRect(x: 14, y: 3, width: 2, height: 2), xRadius: 0.5, yRadius: 0.5)
		pointtopPath.fill()

		let handPath = NSBezierPath()
		handPath.move(to: NSPoint(x: 15, y: 8))
		handPath.line(to: NSPoint(x: 15, y: 15.28))
		handPath.line(to: NSPoint(x: 15.01, y: 15.28))
		handPath.line(to: NSPoint(x: 19, y: 19))
		handPath.lineWidth = lineWidth
		handPath.lineCapStyle = .round
		handPath.lineJoinStyle = .round
		handPath.stroke()
	}

}
