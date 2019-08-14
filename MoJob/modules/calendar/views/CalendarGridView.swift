//
//  CalendarGridView.swift
//  MoJob
//
//  Created by Martin Schneider on 11.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


protocol CalendarDayDelegeate {
	func select(_ day: Date)
}

extension CalendarDayDelegeate {
	func select(_ day: Date) {}
}


class CalendarGridView: NSGridView {

	private let calendar = NSCalendar.current
	private let empty = NSGridCell.emptyContentView
	private let bgShapeLayer = CAShapeLayer()
	private var gradientCircle = GradientCircle()
	private var activeIndicator = ActiveIndicator()
	private var currentSelection = Date().startOfDay!
	private var selectedMonth: DateComponents?

	private var observer: NSObjectProtocol?

	var job: Job? {
		didSet {
			reloadData(for: selectedMonth ?? calendar.dateComponents([.month, .year], from: currentSelection))
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
		for _ in 0..<numberOfRows {
			removeRow(at: 0)
		}

		subviews.removeAll()

		gradientCircle.frame = NSRect(x: frame.maxX, y: frame.maxY, width: 150, height: 150)
		subviews.insert(gradientCircle, at: 0)

		// row with titles
		let fakeLabel = dayLabel(with: "") // avoid blue background on default "empty" view of NSGridCell
		var dayRow: [NSView] = [fakeLabel]
		for i in 1...6 {
			dayRow.append(dayLabel(with: calendar.shortWeekdaySymbols[i]))
		}
		dayRow.append(dayLabel(with: calendar.shortWeekdaySymbols[0]))
		addRow(with: dayRow)

		rowAlignment = .none
		translatesAutoresizingMaskIntoConstraints = false
		columnSpacing = 0
		rowSpacing = 0
		setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 750), for: .horizontal)
		setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 750), for: .vertical)

		NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .mouseEntered, .mouseExited]) {
			let location = $0.locationInWindow
			var localPoint = self.convert(location, from: nil)
			var frame = self.gradientCircle.frame
			frame.origin = localPoint

			localPoint.x -= frame.width / 2
			localPoint.y -= frame.height / 2
			self.gradientCircle.frame.origin = CGPoint(x: localPoint.x + $0.deltaX, y: localPoint.y - $0.deltaY)

			return $0
		}

		observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "calendar:changedDate"), object: nil, queue: nil, using: { notification in
			guard notification.name == .init("calendar:changedDate"), let date = notification.object as? [String: Any], let day = date["day"] as? Date else{ return }

			self.subviews.forEach({
				if let view = $0 as? CalendarDay, let viewDay = view.day {
					view.isSelected = viewDay == day

					if (viewDay == day) {
						let frame = view.frame

						self.activeIndicator.setFrameSize(frame.size)
						if (self.activeIndicator.isHidden) {
							self.activeIndicator.setFrameOrigin(frame.origin)
							self.activeIndicator.isHidden = false
						} else {
							NSAnimationContext.beginGrouping()
							NSAnimationContext.current.duration = 0.5
							self.activeIndicator.animator().setFrameOrigin(frame.origin)
							NSAnimationContext.endGrouping()
						}
					}
				}
			})

			self.currentSelection = day
		})
	}

	override func draw(_ dirtyRect: NSRect) {
		if let view = self.subviews.first(where: {
			if (($0 as? CalendarDay)?.day == currentSelection) {
				return true
			}

			return false
		}), activeIndicator.frame.size.width == 0 {
			let frame = view.frame

			activeIndicator.setFrameOrigin(frame.origin)
			activeIndicator.setFrameSize(frame.size)
		}
	}

	func reloadData(for month: DateComponents) {
		selectedMonth = month

		for _ in 1..<numberOfRows {
			removeRow(at: 1)
		}

		subviews.removeAll(where: { !$0.isKind(of: NSTextField.self) && !$0.isKind(of: GradientCircle.self) })

		if (!calendar.date(currentSelection, matchesComponents: month)) {
			activeIndicator.isHidden = true
		}

		// row for days
		let firstDayOfCalender = calendar.date(from: month)?.startOfWeek
		let lastDayOfCalendar = Calendar.current.date(byAdding: .second, value: -1, to: (calendar.date(from: month)?.endOfMonth?.endOfWeek)!)
		var dayCount = lastDayOfCalendar?.timeIntervalSince(firstDayOfCalender!)
		dayCount = round(dayCount! / 60 / 60 / 24) - 1
		var day = firstDayOfCalender
		var weekSum: Double = 0

		var gridRow: [NSView] = []
		for i in 0...Int(dayCount!) {
			let columnNumber = i.remainderReportingOverflow(dividingBy: 7).partialValue

			let sum = CoreDataHelper.seconds(for: day!, and: job)
			let formatter = DateComponentsFormatter()
			formatter.unitsStyle = .positional
			formatter.zeroFormattingBehavior = .pad
			formatter.allowedUnits = [.hour, .minute]

			weekSum += sum ?? 0

			let content = CalendarDay()
			content.delegate = self
			content.day = day
			content.isCurrentMonth = calendar.date(day!, matchesComponents: month)
			content.timeLabel.stringValue = formatter.string(from: sum ?? 0)!

			if calendar.dateComponents([.day, .month, .year], from: currentSelection) == calendar.dateComponents([.day, .month, .year], from: day!) {
				activeIndicator.isHidden = false
				content.isSelected = true
			}

			gridRow.append(content)

			if (columnNumber == 6) {
				let weekNumber = calendar.component(.weekOfYear, from: day!)
				let content = CalendarWeek()
				content.weekLabel.stringValue = String(weekNumber)
				content.timeLabel.stringValue = formatter.string(from: weekSum)!
				gridRow.insert(content, at: 0)

				addRow(with: gridRow)
				gridRow = []
				weekSum = 0
			}

			day = calendar.date(byAdding: .day, value: 1, to: day!)
		}

		subviews.append(activeIndicator)
	}

	private func dayLabel(with dayNumber: String) -> NSTextField {
		let label = NSTextField(string: dayNumber)
		label.isEditable = false
		label.isBordered = false
		label.drawsBackground = false
		label.wantsLayer = true
		label.layer?.backgroundColor = NSColor.white.cgColor
		label.font = NSFont.systemFont(ofSize: 15, weight: .ultraLight)

		let pstyle = NSMutableParagraphStyle()
		pstyle.lineSpacing = 10.0
		pstyle.alignment = .center
		pstyle.lineHeightMultiple = 1.2
		label.attributedStringValue = NSAttributedString(
			string: dayNumber,
			attributes: [
				NSAttributedString.Key.paragraphStyle: pstyle
			]
		)

		return label
	}

}

extension CalendarGridView: CalendarDayDelegeate {

	func select(_ day: Date) {
		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "calendar:changedDate"), object: ["day": day, "job": job as Any])
	}

}
