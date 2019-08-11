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
		super.draw(dirtyRect)

		let ellipseRect = NSRect(x: 0, y: 0, width: dirtyRect.width, height: dirtyRect.height)
		let ellipseCenterRect = NSInsetRect(ellipseRect, 0, 0)
		NSColor.white.withAlphaComponent(0).set()

		let ellipseCenter = NSBezierPath(ovalIn: ellipseCenterRect)
		ellipseCenter.fill()

		ellipseCenter.setClip()

		let bottomGlowGradient = NSGradient(colorsAndLocations: (NSColor.controlAccentColor, 0.3), (NSColor.white.withAlphaComponent(0), 0.7), (NSColor.white.withAlphaComponent(0), 1))
		bottomGlowGradient?.draw(in: ellipseCenterRect, relativeCenterPosition: NSPoint(x: 0, y: 0))

	}

}
