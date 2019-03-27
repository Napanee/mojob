//
//  Password.swift
//  MoJob
//
//  Created by Martin Schneider on 24.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class Password: NSSecureTextField {

	let underscoreLayer = CALayer()
	let borderColor: NSColor = NSColor.placeholderTextColor

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
		wantsLayer = true

		let lineWidth: CGFloat = 1
		let posTop = bounds.maxY - (lineWidth / 2)
		let lineColor = NSColor.quaternaryLabelColor.cgColor

		let path = NSBezierPath()
		path.move(to: NSPoint(x: bounds.width, y: posTop))
		path.line(to: NSPoint(x: 0, y: posTop))
		let underscore = CAShapeLayer()
		underscore.strokeColor = lineColor
		underscore.lineWidth = lineWidth
		underscore.path = path.cgPath

		layer?.addSublayer(underscore)
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)
	}

	override func becomeFirstResponder() -> Bool {
		super.becomeFirstResponder()

		let curEditor = self.currentEditor()
		curEditor?.selectedRange = NSRange(location: 0, length: 0)

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
		let lineWidth: CGFloat = 1
		let posTop = bounds.maxY - (lineWidth / 2)
		let lineColor = NSColor.controlAccentColor.cgColor

		let animation = CABasicAnimation(keyPath: "strokeEnd")
		animation.fromValue = 0
		animation.duration = 0.2

		let leftPath = NSBezierPath()
		leftPath.move(to: NSPoint(x: bounds.width / 2, y: posTop))
		leftPath.line(to: NSPoint(x: 0, y: posTop))
		let leftUnderscore = CAShapeLayer()
		leftUnderscore.strokeColor = lineColor
		leftUnderscore.lineWidth = lineWidth
		leftUnderscore.path = leftPath.cgPath
		leftUnderscore.add(animation, forKey: "underscoreLeft")

		let rightPath = NSBezierPath()
		rightPath.move(to: NSPoint(x: bounds.width / 2, y: posTop))
		rightPath.line(to: NSPoint(x: bounds.width, y: posTop))
		let rightUnderscore = CAShapeLayer()
		rightUnderscore.strokeColor = lineColor
		rightUnderscore.lineWidth = lineWidth
		rightUnderscore.path = rightPath.cgPath
		rightUnderscore.add(animation, forKey: "underscoreRight")

		underscoreLayer.addSublayer(leftUnderscore)
		underscoreLayer.addSublayer(rightUnderscore)

		layer?.addSublayer(underscoreLayer)
	}

}
