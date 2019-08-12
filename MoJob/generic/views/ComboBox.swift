//
//  ComboBox.swift
//  MoJob
//
//  Created by Martin Schneider on 04.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class ComboBox: NSComboBox {

	override var isEnabled: Bool {
		didSet {
			alphaValue = isEnabled ? 1.0 : 0.5
		}
	}

	let underscoreLayer = CAShapeLayer()
	let underscoreLayerActive = CALayer()
	let borderColor: NSColor = NSColor.placeholderTextColor
	var path: NSBezierPath {
		get {
			let lineWidth: CGFloat = 1
			let posTop = bounds.maxY - (lineWidth / 2)
			let path = NSBezierPath()
			path.move(to: NSPoint(x: bounds.width, y: posTop))
			path.line(to: NSPoint(x: 0, y: posTop))

			return path
		}
	}

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
		isButtonBordered = false
		focusRingType = .none
		font = NSFont.systemFont(ofSize: 20, weight: .light)
		usesDataSource = true
		wantsLayer = true
		lineBreakMode = .byTruncatingTail

		let lineWidth: CGFloat = 1
		let lineColor = NSColor.quaternaryLabelColor.cgColor

		underscoreLayer.strokeColor = lineColor
		underscoreLayer.lineWidth = lineWidth
		underscoreLayer.path = path.cgPath

		layer?.addSublayer(underscoreLayer)
	}

	override func draw(_ dirtyRect: NSRect) {
		if let subLayer = layer?.sublayers?.first(where: { $0.isEqual(to: underscoreLayer) }) as? CAShapeLayer {
			subLayer.path = path.cgPath
		}
	}

	override func becomeFirstResponder() -> Bool {
		if (isEnabled) {
			setFocused()
		}

		return super.becomeFirstResponder()
	}

	override func mouseDown(with event: NSEvent) {
		super.mouseDown(with: event)

		if (isEnabled) {
			setFocused()
		}
	}

	override func textDidEndEditing(_ notification: Notification) {
		super.textDidEndEditing(notification)

		layer?.sublayers?.first(where: { $0.isEqual(underscoreLayerActive) })?.removeFromSuperlayer()
		underscoreLayerActive.sublayers?.removeAll()
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

		underscoreLayerActive.addSublayer(leftUnderscore)
		underscoreLayerActive.addSublayer(rightUnderscore)

		layer?.addSublayer(underscoreLayerActive)
	}

}
