//
//  GraphView.swift
//  MoJob
//
//  Created by Martin Schneider on 13.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


@IBDesignable
class GraphView: NSView {

	var trackings: [Tracking]? {
		didSet {
			needsDisplay = true
		}
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		let context = NSGraphicsContext.current?.cgContext
		drawBarGraphInContext(context: context)
	}

	func drawRoundedRect(rect: CGRect, inContext context: CGContext?, radius: CGFloat, borderColor: CGColor, fillColor: CGColor) {
		let path = CGMutablePath()

		path.move(to: CGPoint(x: rect.midX, y: rect.minY))
		path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: radius)
		path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: radius)
		path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.minY), radius: radius)
		path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY), radius: radius)
		path.closeSubpath()

		context?.setLineWidth(1.0)
		context?.setFillColor(fillColor)
		context?.setStrokeColor(borderColor)

		context?.addPath(path)
		context?.drawPath(using: .fillStroke)
	}

	func barChartRectangle() -> CGRect {
		return CGRect(origin: bounds.origin, size: bounds.size)
	}

	func drawBarGraphInContext(context: CGContext?) {
		let barChartRect = barChartRectangle()
		drawRoundedRect(rect: barChartRect, inContext: context, radius: 4.0, borderColor: NSColor.tertiaryLabelColor.cgColor, fillColor: NSColor.white.cgColor)

		guard let trackings = trackings else { return }

		let durations = trackings.map({ $0.duration })
		let sum = durations.reduce(0.0, +)
		var clipRect = barChartRect
		var moJobColors: NSColorList?

		if let path = Bundle.main.path(forResource: "MoJob", ofType: "clr") {
			moJobColors = NSColorList(name: "MoJob", fromFile: path)
		}

		for tracking in trackings {
			let clipWidth = round(barChartRect.width * CGFloat(tracking.duration) / CGFloat(sum) * CGFloat(sum) / CGFloat(8 * 60 * 60))

			clipRect.size.width = clipWidth

			context?.saveGState()
			context?.clip(to: clipRect)

			var colors = (strokeColor: NSColor.tertiaryLabelColor, fillColor: NSColor(red: 0.878, green: 0.878, blue: 0.878, alpha: 1))
			if let jobColor = tracking.job?.color, let moJobColors = moJobColors, let color = moJobColors.color(withKey: jobColor) {
				colors = (strokeColor: NSColor.tertiaryLabelColor, fillColor: color)
			}

			drawRoundedRect(rect: barChartRect, inContext: context, radius: 0.4, borderColor: colors.strokeColor.cgColor, fillColor: colors.fillColor.cgColor)
			context?.restoreGState()

			clipRect.origin.x = clipRect.maxX
		}
	}

}
