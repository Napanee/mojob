//
//  CalendarDay.swift
//  MoJob
//
//  Created by Martin Schneider on 10.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa
import CoreGraphics


class CalendarDay: NSView {

	@IBOutlet var contentView: NSView!
	@IBOutlet weak var dayLabel: NSTextField!
	@IBOutlet weak var timeLabel: NSTextField!

	let calendar = Calendar.current

	var isSelected: Bool? {
		didSet {
			if let isSelected = isSelected, isSelected {
				contentView.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
				dayLabel.font = NSFont.systemFont(ofSize: 20, weight: .light)
			} else {
				contentView.layer?.backgroundColor = CGColor.clear
				dayLabel.font = NSFont.systemFont(ofSize: 20, weight: .ultraLight)
			}
		}
	}

	var day: Date? {
		didSet {
			if let sum = CoreDataHelper.seconds(for: day!) {
				let formatter = DateComponentsFormatter()
				formatter.unitsStyle = .positional
				formatter.zeroFormattingBehavior = .pad
				formatter.allowedUnits = [.hour, .minute]

				timeLabel.stringValue = formatter.string(from: sum)!
			}

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

		commonInit()
	}

	required init?(coder decoder: NSCoder) {
		super.init(coder: decoder)

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
			NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)
		])
	}

	@IBAction func button(_ sender: NSButton) {
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "calendar:changedDate"), object: ["day": day])
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		guard let context = NSGraphicsContext.current?.cgContext else { return }
		context.addRect(CGRect(x: 1, y: 1, width: bounds.width - 2, height: bounds.height - 2))
		context.setFillColor(NSColor.white.cgColor)
		context.fillPath()
	}

}
