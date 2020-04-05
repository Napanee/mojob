//
//  StopButton.swift
//  MoJob
//
//  Created by Martin Schneider on 27.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class StopButton: NSButton {

	let timeSecondsShapeLayer = CAShapeLayer()
	let startAngle: CGFloat = -90
	let endAngle: CGFloat = 270
	let strokeWidth: CGFloat = 2.0

	var center: CGPoint!
	var radius: CGFloat!
    
	override var isEnabled: Bool {
		didSet {
			if (isEnabled) {
				self.toolTip = "Tracking stoppen."
			} else {
				self.toolTip = "Es muss ein Job, eine Aufgabe und eine Tätigkeit ausgewählt werden."
			}
		}
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		let circle = NSBezierPath(ovalIn: NSRect(x: 1, y: 1, width: bounds.width - 2, height: bounds.height - 2))
		circle.lineWidth = 2.0
		NSColor.white.withAlphaComponent(0.25).setStroke()
		circle.stroke()

		let stop = NSBezierPath(roundedRect: NSRect(x: 10, y: 10, width: 10, height: 10), xRadius: 1.0, yRadius: 1.0)
		stop.lineWidth = 1.5
		if (isEnabled) {
			NSColor.red.setFill()
			stop.fill()
			NSColor.white.setStroke()
		} else {
			NSColor.white.withAlphaComponent(0.5).setStroke()
		}
		stop.stroke()

		if let _ = layer?.sublayers?.first(where: { $0.isEqual(timeSecondsShapeLayer) }) {
			return
		}

		center = CGPoint(x: bounds.midX, y: bounds.midY)
		radius = (bounds.size.width - strokeWidth) * 0.5
		let path = NSBezierPath()
		path.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

		timeSecondsShapeLayer.path = path.cgPath
		timeSecondsShapeLayer.strokeColor = NSColor.white.cgColor
		timeSecondsShapeLayer.fillColor = CGColor.clear
		timeSecondsShapeLayer.lineWidth = strokeWidth

		addAnimation()

		layer?.addSublayer(timeSecondsShapeLayer)
	}

	func addAnimation() {
		self.timeSecondsShapeLayer.removeAllAnimations()

		let animation = CABasicAnimation(keyPath: "strokeEnd")
		var start: Double = 0
		var duration: CFTimeInterval = 60

		if let currentTrackingDuration = CoreDataHelper.currentTracking?.duration {
			let rest = currentTrackingDuration.truncatingRemainder(dividingBy: duration)
			start = rest / duration
			duration = duration - rest
		}

		if (start == 0) {
			animation.repeatCount = .infinity
		}

		animation.fromValue = start
		animation.toValue = 1
		animation.duration = duration
		CATransaction.setCompletionBlock {
			if let _ = self.window {
				self.addAnimation()
			}
		}
		timeSecondsShapeLayer.add(animation, forKey: nil)
		CATransaction.commit()
	}

}
