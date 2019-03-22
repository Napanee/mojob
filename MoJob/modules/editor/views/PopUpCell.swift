//
//  PopUpCell.swift
//  SplitViewResize
//
//  Created by Martin Schneider on 20.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class PopUpCell: NSPopUpButtonCell {

	override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {
		controlView.wantsLayer = true
		controlView.layer?.backgroundColor = NSColor.red.cgColor
	}

	override func imageRect(forBounds rect: NSRect) -> NSRect {
		return NSRect(x: 8, y: 5, width: 49, height: 19)
	}

}
