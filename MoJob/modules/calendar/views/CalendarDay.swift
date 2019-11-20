//
//  CalendarDay.swift
//  MoJob
//
//  Created by Martin Schneider on 10.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa
import CoreGraphics
import Crashlytics


class CalendarDay: NSView {

	@IBOutlet var contentView: NSView!
	@IBOutlet weak var dayLabel: NSTextField!
	@IBOutlet weak var timeLabel: NSTextField!

	var delegate: CalendarDayDelegeate?
	let calendar = Calendar.current

	var isSelected: Bool? {
		didSet {
			if let isSelected = isSelected, isSelected {
				dayLabel.font = NSFont.systemFont(ofSize: 20, weight: .light)
			} else {
				dayLabel.font = NSFont.systemFont(ofSize: 20, weight: .ultraLight)
			}
		}
	}

	var missingHours: Bool? {
		didSet {
			needsLayout = missingHours!
		}
	}

	var isFreeDay: Bool? {
		didSet {
			if let isFreeDay = isFreeDay, isFreeDay {
				dayLabel.textColor = NSColor.tertiaryLabelColor
				timeLabel.textColor = NSColor.tertiaryLabelColor
			}
		}
	}

	var day: Date? {
		didSet {
			let currentDay = calendar.component(.day, from: day!)
			dayLabel.stringValue = String(currentDay)
		}
	}

	var isCurrentMonth: Bool? {
		didSet {
			if let isCurrentMonth = isCurrentMonth, isCurrentMonth {
				dayLabel.textColor = NSColor.labelColor
				timeLabel.textColor = NSColor.secondaryLabelColor
			} else {
				dayLabel.textColor = NSColor.tertiaryLabelColor
				timeLabel.textColor = NSColor.tertiaryLabelColor
			}
		}
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)

		self.delegate = nil

		commonInit()
	}

	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)

		self.delegate = nil

		commonInit()
	}

	private func commonInit() {
		Bundle.main.loadNibNamed("CalendarDay", owner: self, topLevelObjects: nil)
		addSubview(contentView)

		contentView.frame = self.bounds
		contentView.autoresizingMask = [.width, .height]
		contentView.wantsLayer = true

		dayLabel.font = NSFont.systemFont(ofSize: 20, weight: .ultraLight)

		addConstraints([
			NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 55),
			NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 45)
		])
	}

	@IBAction func button(_ sender: NSButton) {
		Answers.logCustomEvent(withName: "Calendar", customAttributes: ["Action": "selectDay"])
		delegate?.select(day!)
	}

	override func draw(_ dirtyRect: NSRect) {
		guard let context = NSGraphicsContext.current?.cgContext else { return }
		context.addRect(CGRect(x: 1, y: 1, width: bounds.width - 2, height: bounds.height - 2))
		context.setFillColor(NSColor.controlBackgroundColor.cgColor)
		context.drawPath(using: .fill)

		guard let missingHours = missingHours, missingHours else { return }

		let rect = CGRect(x: bounds.maxX - 8, y: bounds.maxY - 8, width: 5, height: 5)
		let clipPath = NSBezierPath(roundedRect: rect, xRadius: 2.0, yRadius: 2.0).cgPath
		context.addPath(clipPath)
		context.setFillColor(NSColor(calibratedRed: 0.796, green: 0.212, blue: 0.114, alpha: 1).cgColor)
		context.drawPath(using: .fill)
	}

}
