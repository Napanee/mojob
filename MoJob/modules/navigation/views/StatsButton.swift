//
//  StatsButton.swift
//  MoJob
//
//  Created by Martin Schneider on 25.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class StatsButton: BaseButton {

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		colorBackgroundDefault.setFill()
		colorForegroundDefault.setStroke()

		if (!isEnabled) {
			colorBackgroundInverted.setFill()
		}

		let rectanglePath = NSBezierPath(rect: NSRect(x: 0.5, y: 0.5, width: 29, height: 29))
		rectanglePath.lineWidth = lineWidth
		rectanglePath.lineJoinStyle = .round
		rectanglePath.fill()
		rectanglePath.stroke()

		// Stats Axis
		if (!isEnabled) {
			colorForegroundInverted.setStroke()
		}

		let axisPath = NSBezierPath()
		axisPath.move(to: NSPoint(x: 27, y: 26.5))
		axisPath.line(to: NSPoint(x: 3.5, y: 26.5))
		axisPath.line(to: NSPoint(x: 3.5, y: 4))
		axisPath.lineWidth = lineWidth
		axisPath.lineCapStyle = .round
		axisPath.lineJoinStyle = .round
		axisPath.stroke()

		// Stats Bars
		if (isEnabled) {
			colorBackgroundInverted.setFill()
		} else {
			colorBackgroundDefault.setFill()
		}

		let bars = [
			NSRect(x: 6, y: 8.5, width: 4, height: 18),
			NSRect(x: 13, y: 19.5, width: 4, height: 7),
			NSRect(x: 20, y: 12.5, width: 4, height: 14)
		]
		for bar in bars {
			let barPath = NSBezierPath(rect: bar)
			barPath.lineWidth = lineWidth
			barPath.lineJoinStyle = .round
			barPath.fill()
		}
	}

}
