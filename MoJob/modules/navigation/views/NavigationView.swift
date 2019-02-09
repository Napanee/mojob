//
//  NavigationView.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class NavigationView: NSView {

	@IBInspectable weak var backgroundColor: NSColor? {
		get {
			return NSColor(cgColor: layer?.backgroundColor ?? CGColor.clear)
		}

		set {
			wantsLayer = true
			layer?.backgroundColor = newValue?.cgColor
		}
	}

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

    }
    
}
