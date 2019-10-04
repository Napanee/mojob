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

	let lineWidth: CGFloat = 1.0
	let underscoreLayer = CAShapeLayer()

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
		drawsBackground = false
		isBordered = false
		isButtonBordered = false
		focusRingType = .none
		font = NSFont.systemFont(ofSize: 18, weight: .light)
		usesDataSource = true
		wantsLayer = true
		lineBreakMode = .byTruncatingTail

		if #available(OSX 10.14, *) {
			underlineColorActive = NSColor.controlAccentColor.cgColor
		}
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		let context = NSGraphicsContext.current?.cgContext
		context?.setLineWidth(lineWidth)
		context?.setStrokeColor(underlineColor)

		let path = CGMutablePath()
		path.move(to: CGPoint(x: bounds.minX, y: bounds.maxY))
		path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
		context?.addPath(path)
		context?.drawPath(using: .stroke)
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

		layer?.sublayers?.first(where: { $0.isEqual(underscoreLayer) })?.removeFromSuperlayer()
		underscoreLayer.sublayers?.removeAll()
	}

	private func setFocused() {
		underscoreLayer.addSublayer(underscoreLayer(end: NSPoint(x: bounds.minX, y: bounds.maxY)))
		underscoreLayer.addSublayer(underscoreLayer(end: NSPoint(x: bounds.maxX, y: bounds.maxY)))

		layer?.addSublayer(underscoreLayer)
	}

	private func underscoreLayer(end: NSPoint) -> CALayer {
		let animation = CABasicAnimation(keyPath: "strokeEnd")
		animation.fromValue = 0
		animation.duration = 0.2

		let path = NSBezierPath()
		let layer = CAShapeLayer()
		path.move(to: NSPoint(x: bounds.midX, y: bounds.maxY))
		path.line(to: end)
		layer.path = path.cgPath
		layer.strokeColor = underlineColorActive
		layer.lineWidth = lineWidth
		layer.add(animation, forKey: nil)

		return layer
	}

}
