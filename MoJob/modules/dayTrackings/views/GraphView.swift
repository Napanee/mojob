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

	override var wantsDefaultClipping: Bool {
		get {
			return false
		}
	}
	var trackingArea: NSTrackingArea?
	var trackings: [Tracking]? {
		didSet {
			if let trackingArea = trackingArea {
				DispatchQueue.main.async {
					self.removeTrackingArea(trackingArea)
					self.trackingArea = nil
				}
			}

			DispatchQueue.main.async {
				self.needsDisplay = true
			}
		}
	}
	var userDefaults = UserDefaults()
	var clipRectangles: [(title: String, rect: CGRect)] = []
	var currentHover: (title: String, rect: CGRect)?

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		let context = NSGraphicsContext.current?.cgContext
		drawBarGraphInContext(context: context)

		if (trackingArea == nil) {
			updateTrackingAreas()
		}
	}

	override func updateTrackingAreas() {
		super.updateTrackingAreas()

		if let trackingArea = trackingArea {
			removeTrackingArea(trackingArea)
			self.trackingArea = nil
		}

		if let lastBounds = clipRectangles.last?.rect {
			let trackingArea = NSTrackingArea(rect: CGRect(x: bounds.minX + 1, y: bounds.minY + 1, width: lastBounds.maxX - 2, height: bounds.height / 2 - 2), options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved], owner: self, userInfo: nil)
			addTrackingArea(trackingArea)

			self.trackingArea = trackingArea
		}
	}

	override func mouseEntered(with event: NSEvent) {
		let localPoint = self.convert(event.locationInWindow, from: nil)
		guard let currentRect = clipRectangles.first(where: { $0.rect.contains(localPoint) }) else { return }

		currentHover = currentRect

		needsDisplay = true
	}

	override func mouseMoved(with event: NSEvent) {
		let localPoint = self.convert(event.locationInWindow, from: nil)
		guard let currentHover = currentHover, let currentRect = clipRectangles.first(where: { $0.rect.contains(localPoint) }) else {
			return
		}

		if (currentHover != currentRect) {
			self.currentHover = currentRect
			needsDisplay = true
		}
	}

	override func mouseExited(with event: NSEvent) {
		currentHover = nil
		needsDisplay = true
	}

	func trackingSet() -> [(id: String, title: String, color: String?, duration: TimeInterval)] {
		guard let trackings = trackings else { return [] }

		var trackingSet: [(id: String, title: String, color: String?, duration: TimeInterval)] = []
		let baseItems = trackings.filter({ $0.job != nil }).map({ (id: $0.job!.id, title: $0.job!.fullTitle, color: $0.job!.color, duration: $0.duration) })

		baseItems.forEach { item in
			if let id = item.id {
				let sum = baseItems.filter { $0.id == item.id }.reduce(0.0) { $0 + $1.duration }
				let obj = (id: id, title: item.title, color: item.color, duration: sum)

				if (!trackingSet.contains(where: { $0 == obj })) {
					trackingSet += [obj]
				}
			}
		}
		trackingSet = trackingSet.sorted { $0.duration > $1.duration }

		return trackingSet
	}

	func drawRect(rect: CGRect, inContext context: CGContext?, borderColor: CGColor, fillColor: CGColor) {
		context?.setLineWidth(1.0)
		context?.setFillColor(fillColor)
		context?.setStrokeColor(borderColor)

		context?.addRect(rect)
		context?.drawPath(using: .fillStroke)
	}

	func drawBarGraphInContext(context: CGContext?) {
		let barChartRect = CGRect(origin: NSPoint(x: 1, y: 1), size: NSSize(width: bounds.size.width - 2, height: bounds.size.height / 2 - 2))
		var clipRect = barChartRect
		drawRect(rect: barChartRect, inContext: context, borderColor: NSColor.tertiaryLabelColor.cgColor, fillColor: NSColor.white.cgColor)

		guard let trackings = trackings else { return }

		let sum = trackings.map({ $0.duration }).reduce(0, +)

		let dayHours = userDefaults.double(forKey: UserDefaults.Keys.notificationDaycomplete)
		let maxTime = max(sum, dayHours * 60 * 60)
		let moJobColors = NSColorList.moJobColorList

		clipRectangles = []
		for tracking in trackingSet() {
			let clipWidth = round(barChartRect.width * CGFloat(tracking.duration / sum * sum / maxTime))

			clipRect.size.width = clipWidth

			clipRectangles.append((title: tracking.title, rect: clipRect))

			context?.saveGState()
			context?.clip(to: clipRect)

			var colors = (strokeColor: NSColor.tertiaryLabelColor, fillColor: NSColor(red: 0.878, green: 0.878, blue: 0.878, alpha: 1))
			if let jobColor = tracking.color, let color = moJobColors.color(withKey: jobColor) {
				colors = (strokeColor: NSColor.tertiaryLabelColor, fillColor: color)
			}

			drawRect(rect: barChartRect, inContext: context, borderColor: colors.fillColor.cgColor, fillColor: colors.fillColor.cgColor)

			context?.restoreGState()

			if (currentHover?.rect == clipRect) {
				let formatter = DateComponentsFormatter()
				formatter.unitsStyle = .abbreviated
				formatter.zeroFormattingBehavior = .pad
				formatter.allowedUnits = [.hour, .minute]

				drawText(with: "\(formatter.string(from: tracking.duration)!) - \(tracking.title)")
			}

			clipRect.origin.x = clipRect.maxX
		}
	}

	private func drawText(with text: String) {
		let timeString = NSString(string: text).range(of: "-")
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.lineBreakMode = .byTruncatingTail

		let attributes: [NSAttributedString.Key: Any] = [
			.paragraphStyle: paragraphStyle,
			.font: NSFont.systemFont(ofSize: 13.0),
			.foregroundColor: NSColor.secondaryLabelColor
		]
		let attributedString = NSAttributedString(string: text, attributes: attributes)
		let string = NSMutableAttributedString(attributedString: attributedString)
		string.addAttribute(.font, value: NSFont.systemFont(ofSize: 13.0, weight: .medium), range: NSRange(location: 0, length: timeString.location))

		let textRect = CGRect(
			origin: bounds.origin.applying(CGAffineTransform(translationX: 5, y: 2)),
			size: CGSize(width: bounds.size.width - 10, height: bounds.size.height)
		)
		string.draw(in: textRect)
	}

}
