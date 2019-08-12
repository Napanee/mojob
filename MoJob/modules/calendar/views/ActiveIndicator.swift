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
		wantsLayer = true
		layer?.borderColor = NSColor.controlAccentColor.cgColor
		layer?.borderWidth = 1

		let rect = NSRect(x: 0, y: 0, width: dirtyRect.width, height: dirtyRect.height)
		NSColor.controlAccentColor.withAlphaComponent(0.2).set()
		rect.fill()

	}

}
