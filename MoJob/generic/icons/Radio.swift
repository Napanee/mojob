//
//  Radio.swift
//  MoJob
//
//  Created by Martin Schneider on 21.11.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class Radio: NSButton {

	let colorForegroundDefault = NSColor.secondaryLabelColor
	let lineWidth: CGFloat = 1.0

	override var title: String {
		didSet {
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
	}

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

		let ovalPath = NSBezierPath(ovalIn: NSRect(x: 0.5, y: 0.5, width: 15, height: 15))
		colorForegroundDefault.setStroke()
		ovalPath.lineWidth = lineWidth
		ovalPath.stroke()

		if (state == .on) {
			let oval2Path = NSBezierPath(ovalIn: NSRect(x: 3.5, y: 3.5, width: 9, height: 9))
			colorForegroundDefault.setFill()
			oval2Path.fill()
		}
	}

}
