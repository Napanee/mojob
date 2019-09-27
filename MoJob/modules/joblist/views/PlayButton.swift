//
//  PlayButton.swift
//  MoJob
//
//  Created by Martin Schneider on 27.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class PlayButton: NSButton {

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		let circlePath = NSBezierPath(ovalIn: NSRect(x: 0.25, y: 0.25, width: 19.5, height: 19.5))
		NSColor.black.setStroke()
		circlePath.lineWidth = 0.5
		circlePath.stroke()

		let playPath = NSBezierPath()
		playPath.move(to: NSPoint(x: 14.25, y: 10))
		playPath.line(to: NSPoint(x: 7.25, y: 6))
		playPath.line(to: NSPoint(x: 7.25, y: 14))
		playPath.close()
		NSColor.black.setStroke()
		playPath.lineWidth = 0.5
		playPath.lineJoinStyle = .round
		playPath.stroke()
	}

}
