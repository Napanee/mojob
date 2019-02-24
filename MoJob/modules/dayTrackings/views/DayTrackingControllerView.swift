//
//  DayTrackingControllerView.swift
//  MoJob
//
//  Created by Martin Schneider on 24.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class DayTrackingControllerView: NSView {
	
	@IBInspectable weak var viewBackgroundColor: NSColor! = NSColor.clear

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		wantsLayer = true
		layer?.backgroundColor = viewBackgroundColor.cgColor
	}

}
