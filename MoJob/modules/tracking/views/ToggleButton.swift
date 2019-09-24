//
//  ToggleButton.swift
//  MoJob
//
//  Created by Martin Schneider on 31.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class ToggleButton: NSButton {

	let strokeWidth: CGFloat = 2.0
	let strokeColor: NSColor = NSColor.white

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		createRoundedTriangle(width: 14, height: 7, radius: 2)
		createCircle()
	}

	func createRoundedTriangle(width: CGFloat, height: CGFloat, radius: CGFloat) {
		let offsetX: CGFloat = (bounds.width - width) / 2
		let offsetY: CGFloat = (bounds.height - height) / 2
		let top: CGFloat = state == .off ? offsetY + height : offsetY
		let bottom: CGFloat = state == .off ? offsetY : offsetY + height
		let pointStart = CGPoint(x: offsetX, y: top)
		let pointCenter = CGPoint(x: offsetX + width / 2, y: bottom)
		let pointEnd = CGPoint(x: offsetX + width, y: top)

		let arrow = NSBezierPath()
		arrow.move(to: pointStart)
		arrow.line(to: pointCenter)
		arrow.line(to: pointEnd)
		arrow.lineWidth = strokeWidth
		arrow.lineJoinStyle = .round
		arrow.lineCapStyle = .round
		strokeColor.setStroke()
		arrow.stroke()
	}

	func createCircle() {
		let circle = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: bounds.width - 2, height: bounds.height - 2))
		circle.lineWidth = strokeWidth
		strokeColor.setStroke()
		circle.stroke()
	}

}
