//
//  GradientCircle.swift
//  MoJob
//
//  Created by Martin Schneider on 11.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class GradientCircle: NSView {

	override func draw(_ dirtyRect: NSRect) {
		let ellipseRect = NSRect(x: 0, y: 0, width: dirtyRect.width, height: dirtyRect.height)
		let ellipseCenterRect = NSInsetRect(ellipseRect, 0, 0)
		NSColor.controlBackgroundColor.withAlphaComponent(0).set()

		let ellipseCenter = NSBezierPath(ovalIn: ellipseCenterRect)
		ellipseCenter.fill()

		ellipseCenter.setClip()

		var color = NSColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 1.0)
		if #available(OSX 10.14, *) {
			color = NSColor.controlAccentColor
		}
		let bottomGlowGradient = NSGradient(colorsAndLocations: (color, 0.3), (color.withAlphaComponent(0), 0.7), (color.withAlphaComponent(0), 1))
		bottomGlowGradient?.draw(in: ellipseCenterRect, relativeCenterPosition: NSPoint(x: 0, y: 0))

	}

}
