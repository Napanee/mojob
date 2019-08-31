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

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		let context = NSGraphicsContext.current?.cgContext
		context?.setLineWidth(strokeWidth)
		context?.setStrokeColor(CGColor.white)

		context?.addPath(createRoundedTriangle(width: 14, height: 8, radius: 2))
		context?.drawPath(using: .stroke)

		context?.addPath(createCircle())
		context?.drawPath(using: .stroke)
	}

	func createRoundedTriangle(width: CGFloat, height: CGFloat, radius: CGFloat) -> CGPath {
		let offsetX: CGFloat = (bounds.width - width) / 2
		let offsetY: CGFloat = (bounds.height - height) / 2
		let top: CGFloat = state.rawValue == 0 ? offsetY + height : offsetY
		let bottom: CGFloat = state.rawValue == 0 ? offsetY : offsetY + height
		let point1 = CGPoint(x: offsetX + width / 2, y: bottom)
		let point2 = CGPoint(x: offsetX + width, y: top)

		let path = CGMutablePath()
		path.move(to: CGPoint(x: offsetX, y: top))
		path.addArc(tangent1End: point1, tangent2End: point2, radius: radius)
		path.addLine(to: point2)

		return path
	}

	func createCircle() -> CGPath {
		let center = CGPoint(x: bounds.midX, y: bounds.midY)
		let radius = (bounds.size.width - strokeWidth) * 0.5
		let startAngle: CGFloat = -90
		let endAngle: CGFloat = 270

		let path = CGMutablePath()
		path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

		return path
	}

}
