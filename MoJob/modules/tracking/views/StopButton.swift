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
	let strokeWidth: CGFloat = 1.0

	var center: CGPoint!
	var radius: CGFloat!

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		if let _ = layer?.sublayers?.first(where: { $0.isEqual(timeSecondsShapeLayer) }) {
			return
		}

		center = CGPoint(x: bounds.midX, y: bounds.midY)
		radius = (bounds.size.width - strokeWidth) * 0.5

		drawStopIcon()

		let path = NSBezierPath()
		path.appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)

		timeSecondsShapeLayer.path = path.cgPath
		timeSecondsShapeLayer.strokeColor = NSColor.white.cgColor
		timeSecondsShapeLayer.fillColor = CGColor.clear
		timeSecondsShapeLayer.lineWidth = strokeWidth

		addAnimation()

		layer?.addSublayer(timeSecondsShapeLayer)
	}

	func drawStopIcon() {
		let context = NSGraphicsContext.current?.cgContext
		context?.setLineWidth(strokeWidth)

		let stopPath = CGMutablePath()
		stopPath.addRoundedRect(in: CGRect(x: 10, y: 10, width: 10, height: 10), cornerWidth: 2.0, cornerHeight: 2.0)
		context?.setStrokeColor(CGColor.white)
		context?.addPath(stopPath)
		context?.drawPath(using: .stroke)

		let stopCircle = CGMutablePath()
		stopCircle.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
		context?.setStrokeColor(NSColor.white.withAlphaComponent(0.25).cgColor)
		context?.addPath(stopCircle)
		context?.drawPath(using: .stroke)
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
