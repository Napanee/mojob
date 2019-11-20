//
//  FavoriteHeadlineView.swift
//  MoJob
//
//  Created by Martin Schneider on 16.10.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


@IBDesignable
class FavoriteHeadlineView: NSView {

	@IBInspectable
	var color: NSColor?

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		if let color = color {
			let indicator = NSBezierPath(roundedRect: NSRect(x: 2, y: dirtyRect.midY - 4, width: 10, height: 10), xRadius: 5.0, yRadius: 5.0)

			indicator.lineWidth = 2.0
			NSColor.secondaryLabelColor.setStroke()
			color.setFill()
			indicator.stroke()
			indicator.fill()
		}
	}

}
