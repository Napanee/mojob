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
	var underlineColor: CGColor = NSColor.quaternaryLabelColor.cgColor
	var underlineColorActive: CGColor = NSColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 1.0).cgColor
	var hasColoredBackground: Bool {
		didSet {
			if (hasColoredBackground) {
				underlineColor = NSColor.white.withAlphaComponent(0.3).cgColor
				underlineColorActive = NSColor.white.cgColor

				underscoreLayer.strokeColor = underlineColor
			}
		}
	}
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
		hasColoredBackground = false

		super.init(frame: frameRect)

		commonInit()
	}

	required init?(coder decoder: NSCoder) {
		hasColoredBackground = false

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

		if #available(OSX 10.14, *) {
			underlineColorActive = NSColor.controlAccentColor.cgColor
		}

		underscoreLayer.strokeColor = underlineColor
		underscoreLayer.lineWidth = 1
		underscoreLayer.path = path.cgPath

		layer?.addSublayer(underscoreLayer)
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

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

		let animation = CABasicAnimation(keyPath: "strokeEnd")
		animation.fromValue = 0
		animation.duration = 0.2

		let leftPath = NSBezierPath()
		leftPath.move(to: NSPoint(x: bounds.width / 2, y: posTop))
		leftPath.line(to: NSPoint(x: 0, y: posTop))
		let leftUnderscore = CAShapeLayer()
		leftUnderscore.strokeColor = underlineColorActive
		leftUnderscore.lineWidth = lineWidth
		leftUnderscore.path = leftPath.cgPath
		leftUnderscore.add(animation, forKey: "underscoreLeft")

		let rightPath = NSBezierPath()
		rightPath.move(to: NSPoint(x: bounds.width / 2, y: posTop))
		rightPath.line(to: NSPoint(x: bounds.width, y: posTop))
		let rightUnderscore = CAShapeLayer()
		rightUnderscore.strokeColor = underlineColorActive
		rightUnderscore.lineWidth = lineWidth
		rightUnderscore.path = rightPath.cgPath
		rightUnderscore.add(animation, forKey: "underscoreRight")

		underscoreLayerActive.addSublayer(leftUnderscore)
		underscoreLayerActive.addSublayer(rightUnderscore)

		layer?.addSublayer(underscoreLayerActive)
	}

}
