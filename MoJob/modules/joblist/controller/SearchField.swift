//
//  SearchField.swift
//  MoJob
//
//  Created by Martin Schneider on 09.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class SearchField: NSTextField {

	var _borderColor: CGColor?
	@IBInspectable weak var borderColor: NSColor! {
		get {
			return NSColor(cgColor: _borderColor ?? CGColor.clear)
		}
		set {
			_borderColor = newValue?.cgColor
		}
	}

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

		focusRingType = NSFocusRingType.none

		let border = CALayer()
		border.frame = CGRect(x: 0, y: bounds.maxY - 1, width: bounds.width, height: 1)
		border.backgroundColor = borderColor.cgColor

        wantsLayer = true
		layer?.addSublayer(border)
    }
    
}
