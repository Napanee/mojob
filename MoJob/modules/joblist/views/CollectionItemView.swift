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
	var trackingArea: NSTrackingArea?

	var _backgroundColor: CGColor?
	@IBInspectable weak var backgroundColor: NSColor! {
		get {
			return NSColor(cgColor: _backgroundColor ?? CGColor.clear)
		}
		set {
			_backgroundColor = newValue?.cgColor
		}
	}

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

		backgroundLayer.backgroundColor = CGColor.clear
		backgroundLayer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)

		layer?.addSublayer(backgroundLayer)
    }

	override func mouseEntered(with event: NSEvent) {
		backgroundLayer.backgroundColor = backgroundColor.cgColor

		let animation = CABasicAnimation(keyPath: "backgroundColor")
		animation.fromValue = CGColor.clear
		animation.toValue = backgroundColor.cgColor
		animation.duration = 0.5
		animation.delegate = self
		backgroundLayer.add(animation, forKey: "bgColor")
	}

	override func mouseExited(with event: NSEvent) {
		backgroundLayer.removeAllAnimations()
		backgroundLayer.backgroundColor = CGColor.clear
	}

	override func updateTrackingAreas() {
		super.updateTrackingAreas()

		if let trackingArea = trackingArea {
			removeTrackingArea(trackingArea)
		}

		trackingArea = NSTrackingArea(
			rect: bounds,
			options: [
				NSTrackingArea.Options.activeAlways,
				NSTrackingArea.Options.mouseEnteredAndExited
			],
			owner: self,
			userInfo: nil
		)

		addTrackingArea(trackingArea!)
	}

}
