//
//  CollectionItemView.swift
//  MoJob
//
//  Created by Martin Schneider on 10.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class CollectionItemView: NSView, CAAnimationDelegate {

	let backgroundLayer = CALayer()

	@IBInspectable weak var backgroundColor: NSColor! = NSColor.clear

	override func draw(_ dirtyRect: NSRect) {
		backgroundLayer.backgroundColor = CGColor.clear
		backgroundLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)

		layer?.insertSublayer(backgroundLayer, at: 0)
	}

	override func mouseExited(with event: NSEvent) {
		backgroundLayer.removeAllAnimations()
		backgroundLayer.backgroundColor = CGColor.clear
	}

	func highlightBackground(is visible: Bool) {
		if (visible) {
			backgroundLayer.backgroundColor = backgroundColor.cgColor
		} else {
			backgroundLayer.backgroundColor = CGColor.clear
		}
	}

}
