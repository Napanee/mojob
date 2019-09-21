//
//  LegendLabel.swift
//  MoJob
//
//  Created by Martin Schneider on 20.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class PaddedTextField: NSTextFieldCell {

	override func drawingRect(forBounds rect: NSRect) -> NSRect {
		let rectInset = NSMakeRect(rect.origin.x + 15.0, rect.origin.y, rect.size.width - 15.0, rect.size.height)
		return super.drawingRect(forBounds: rectInset)
	}

}

class LegendLabel: NSTextField {

	var color: NSColor?

	override init(frame frameRect: NSRect) {
		super.init(frame: NSRect(x: frameRect.minX, y: frameRect.minY, width: frameRect.width, height: frameRect.height))

		commonInit()
	}

	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)

		commonInit()
	}

	private func commonInit() {
		self.cell = PaddedTextField(textCell: "")
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		let context = NSGraphicsContext.current?.cgContext
		context?.setLineWidth(1.0)
		context?.setFillColor(color?.cgColor ?? NSColor.gray.cgColor)

		context?.addRect(CGRect(x: 3, y: 2, width: 10, height: 10))
		context?.drawPath(using: .fill)
	}

}
