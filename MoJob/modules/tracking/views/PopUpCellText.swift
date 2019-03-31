//
//  PopUpCellText.swift
//  MoJob
//
//  Created by Martin Schneider on 30.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class PopUpCellText: NSPopUpButtonCell {

	override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {
		controlView.wantsLayer = true
		controlView.layer?.backgroundColor = NSColor.red.cgColor
	}

	override func titleRect(forBounds cellFrame: NSRect) -> NSRect {
		return NSRect(x: 0, y: 0, width: cellFrame.width - 20, height: cellFrame.height)
	}

}
