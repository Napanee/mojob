//
//  TextField.swift
//  MoJob
//
//  Created by Martin Schneider on 08.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TextField: NSTextField {

	let lineWidth: CGFloat = 1.0
	let underscoreLayer = CAShapeLayer()

	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)

		commonInit()
	}

	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)

		commonInit()
	}

	private func commonInit() {
		isBordered = false
		backgroundColor = NSColor.clear
		focusRingType = .none
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		let context = NSGraphicsContext.current?.cgContext
		context?.setLineWidth(lineWidth)
		context?.setStrokeColor(NSColor.quaternaryLabelColor.cgColor)

		let path = CGMutablePath()
		path.move(to: CGPoint(x: bounds.minX, y: bounds.maxY))
		path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
		context?.addPath(path)
		context?.drawPath(using: .stroke)
	}

	override func becomeFirstResponder() -> Bool {
		super.becomeFirstResponder()

		setFocused()

		return true
	}

	override func mouseDown(with event: NSEvent) {
		super.mouseDown(with: event)

		setFocused()
	}

	override func textDidEndEditing(_ notification: Notification) {
		super.textDidEndEditing(notification)

		layer?.sublayers?.first(where: { $0.isEqual(underscoreLayer) })?.removeFromSuperlayer()
		underscoreLayer.sublayers?.removeAll()
	}

	private func setFocused() {
		underscoreLayer.addSublayer(underscoreLayer(end: NSPoint(x: bounds.minX, y: bounds.maxY)))
		underscoreLayer.addSublayer(underscoreLayer(end: NSPoint(x: bounds.maxX, y: bounds.maxY)))

		layer?.addSublayer(underscoreLayer)
	}

	private func underscoreLayer(end: NSPoint) -> CALayer {
		var lineColor = NSColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 1.0).cgColor
		if #available(OSX 10.14, *) {
			lineColor = NSColor.controlAccentColor.cgColor
		}

		let animation = CABasicAnimation(keyPath: "strokeEnd")
		animation.fromValue = 0
		animation.duration = 0.2

		let path = NSBezierPath()
		let layer = CAShapeLayer()
		path.move(to: NSPoint(x: bounds.midX, y: bounds.maxY))
		path.line(to: end)
		layer.path = path.cgPath
		layer.strokeColor = lineColor
		layer.lineWidth = lineWidth
		layer.add(animation, forKey: nil)

		return layer
	}

}
