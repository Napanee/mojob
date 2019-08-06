//
//  Timer.swift
//  MoJob
//
//  Created by Martin Schneider on 10.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

@IBDesignable class TimerCount: NSView {

	let bgShapeLayer = CAShapeLayer()
	let timeSecondsShapeLayer = CAShapeLayer()

	@IBInspectable var circleBackgroundColor: NSColor = NSColor.white
	@IBInspectable var circleSecondsColor: NSColor = NSColor.red
	@IBInspectable var circleLineWidth: Int = 5

	var counter: CGFloat = 0 {
		didSet {
			needsDisplay = true
		}
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		drawBgShape()
		drawTimeSecondsShape()

		let animation = CABasicAnimation(keyPath: "strokeEnd")
		animation.fromValue = (counter - 1) / counter
		animation.toValue = 1
		animation.duration = 0.25
		timeSecondsShapeLayer.add(animation, forKey: "angle")
	}

	func drawBgShape() {
		let rect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.width)
		let path = NSBezierPath()
		let center = CGPoint(x: rect.midX, y: rect.midY)
		let radius = rect.size.width / 2.0 - CGFloat(circleLineWidth) / 2
		path.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: -270, clockwise: true)

		bgShapeLayer.path = path.cgPath
		bgShapeLayer.strokeColor = circleBackgroundColor.cgColor
		bgShapeLayer.fillColor = CGColor.clear
		bgShapeLayer.lineWidth = CGFloat(circleLineWidth)

		layer?.addSublayer(bgShapeLayer)
	}

	func drawTimeSecondsShape() {
		let rect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.width)
		let path = NSBezierPath()
		let center = CGPoint(x: rect.midX, y: rect.midY)
		let radius = rect.size.width / 2.0 - CGFloat(circleLineWidth) / 2
		path.appendArc(withCenter: center, radius: radius, startAngle: 90, endAngle: 90 - (counter / 60) * 360, clockwise: true)

		timeSecondsShapeLayer.path = path.cgPath
		timeSecondsShapeLayer.strokeColor = circleSecondsColor.cgColor
		timeSecondsShapeLayer.fillColor = CGColor.clear
		timeSecondsShapeLayer.lineWidth = CGFloat(circleLineWidth) // circleLineWidth

		layer?.addSublayer(timeSecondsShapeLayer)
	}
    
}
