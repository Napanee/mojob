//
//  FilterField.swift
//  MoJob
//
//  Created by Martin Schneider on 09.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class FilterField: NSTextField {

	var _borderColor: CGColor?
	@IBInspectable weak var borderColor: NSColor! = NSColor.clear

	weak var customDelegate: FilterFieldDelegate?

	required init?(coder: NSCoder) {
		super.init(coder: coder)

		NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown, handler: myKeyDownEvent)
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		focusRingType = NSFocusRingType.none

		let border = CALayer()
		border.frame = CGRect(x: 0, y: bounds.maxY - 1, width: bounds.width, height: 1)
		border.backgroundColor = CGColor.clear // borderColor.cgColor

		wantsLayer = true
		layer?.addSublayer(border)
	}

	func myKeyDownEvent(event: NSEvent) -> NSEvent? {
		customDelegate?.keyDown(keyCode: event.keyCode)

		if ([125, 126].contains(event.keyCode)) {
			return nil
		}

		return event
	}

}
