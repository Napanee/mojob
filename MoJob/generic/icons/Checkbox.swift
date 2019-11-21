//
//  Checkbox.swift
//  MoJob
//
//  Created by Martin Schneider on 21.11.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class Checkbox: NSButton {

	let colorForegroundDefault = NSColor.secondaryLabelColor
	let lineWidth: CGFloat = 1.0

	override func alignmentRect(forFrame frame: NSRect) -> NSRect {
		return NSRect(x: frame.minX, y: frame.minY, width: frame.width + 20, height: frame.height)
	}

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)

		commonInit()
	}

	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)

		commonInit()
	}

	private func commonInit() {
		let pstyle = NSMutableParagraphStyle()
		pstyle.firstLineHeadIndent = 20.0
		let attributes = [
			NSAttributedString.Key.foregroundColor: NSColor.secondaryLabelColor,
			NSAttributedString.Key.paragraphStyle: pstyle
		]

		attributedTitle = NSAttributedString(
			string: title,
			attributes: attributes
		)

		attributedAlternateTitle = NSAttributedString(
			string: title,
			attributes: attributes
		)
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		let rectPath = NSBezierPath()
		rectPath.move(to: NSPoint(x: 9.2, y: 0.5))
		rectPath.line(to: NSPoint(x: 0.5, y: 0.5))
		rectPath.line(to: NSPoint(x: 0.5, y: 15.5))
		rectPath.line(to: NSPoint(x: 15.5, y: 15.5))
		rectPath.line(to: NSPoint(x: 15.5, y: 6.93))
		colorForegroundDefault.setStroke()
		rectPath.lineWidth = lineWidth
		rectPath.miterLimit = 4
		rectPath.lineCapStyle = .round
		rectPath.lineJoinStyle = .round
		rectPath.stroke()

		if (state == .on) {
			let checkPath = NSBezierPath()
			checkPath.move(to: NSPoint(x: 2.93, y: 7.71))
			checkPath.line(to: NSPoint(x: 7.38, y: 11.65))
			checkPath.line(to: NSPoint(x: 15.29, y: 1.11))
			colorForegroundDefault.setStroke()
			checkPath.lineWidth = lineWidth
			checkPath.miterLimit = 4
			checkPath.lineCapStyle = .round
			checkPath.lineJoinStyle = .round
			checkPath.stroke()
		}
	}

}
