//
//  ActiveIndicator.swift
//  MoJob
//
//  Created by Martin Schneider on 11.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class ActiveIndicator: NSView {

	override func draw(_ dirtyRect: NSRect) {
		var color = NSColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 1.0)

		if #available(OSX 10.14, *) {
			color = NSColor.controlAccentColor
		}

		wantsLayer = true
		layer?.borderColor = color.cgColor
		layer?.borderWidth = 1

		let rect = NSRect(x: 0, y: 0, width: dirtyRect.width, height: dirtyRect.height)
		color.withAlphaComponent(0.2).set()
		rect.fill()

	}

}
