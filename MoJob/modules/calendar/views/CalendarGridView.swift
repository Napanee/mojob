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

	private let userDefaults = UserDefaults()
	private let calendar = NSCalendar.current
	private let empty = NSGridCell.emptyContentView
	private let bgShapeLayer = CAShapeLayer()
	var gradientCircle = GradientCircle()
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
		var weekNumber = calendar.component(.weekOfYear, from: day!)
		var weekSum: Double = 0

		var evenWeekDays = userDefaults.array(forKey: UserDefaults.Keys.evenWeekDays) as? [Int] ?? []
		evenWeekDays = evenWeekDays + [0, 6] // add saturday and sunday
		var oddWeekDays = userDefaults.array(forKey: UserDefaults.Keys.oddWeekDays) as? [Int] ?? []
		oddWeekDays = oddWeekDays + [0, 6] // add saturday and sunday
		let evenWeekHours = userDefaults.integer(forKey: UserDefaults.Keys.evenWeekHours)
		let evenWorkHours = Double(evenWeekHours) / Double(7 - evenWeekDays.count) * 3600
		let oddWeekHours = userDefaults.integer(forKey: UserDefaults.Keys.oddWeekHours)
		let oddWorkHours = Double(oddWeekHours) / Double(7 - oddWeekDays.count) * 3600

		var gridRow: [NSView] = []
		for i in 0...Int(dayCount!) {
			let columnNumber = i.remainderReportingOverflow(dividingBy: 7).partialValue
			let sum = CoreDataHelper.seconds(from: (day?.startOfDay)!, byAdding: .day, and: job) ?? 0
			let formatter = DateComponentsFormatter()
			formatter.unitsStyle = .positional
			formatter.zeroFormattingBehavior = .pad
			formatter.allowedUnits = [.hour, .minute]

			weekSum += sum

			let isEvenWeek = (weekNumber % 2) == 0
			let weekDayNumber = calendar.component(.weekday, from: day!) - 1
			let isFreeDay = isEvenWeek && evenWeekDays.contains(weekDayNumber) || !isEvenWeek && oddWeekDays.contains(weekDayNumber)
			let content = CalendarDay()
			content.delegate = self
			content.day = day
			content.isCurrentMonth = calendar.date(day!, matchesComponents: month)
			content.isFreeDay = isFreeDay
			content.missingHours = day?.compare(Date()) == ComparisonResult.orderedAscending && !isFreeDay && ((isEvenWeek && sum - evenWorkHours < 0) || (!isEvenWeek && sum - oddWorkHours < 0))
			content.timeLabel.stringValue = formatter.string(from: sum)!

			if calendar.dateComponents([.day, .month, .year], from: currentSelection) == calendar.dateComponents([.day, .month, .year], from: day!) {
				activeIndicator.isHidden = false
				content.isSelected = true
			}

			gridRow.append(content)

			day = calendar.date(byAdding: .day, value: 1, to: day!)

			if (columnNumber == 6) {
				let content = CalendarWeek()
				content.weekLabel.stringValue = String(weekNumber)
				content.timeLabel.stringValue = formatter.string(from: weekSum)!
				gridRow.insert(content, at: 0)

				addRow(with: gridRow)
				gridRow = []
				weekSum = 0

				weekNumber = calendar.component(.weekOfYear, from: day!)
			}
		}

		subviews.append(activeIndicator)
	}

	private func dayLabel(with dayNumber: String) -> NSTextField {
		let label = NSTextField(string: dayNumber)
		label.isEditable = false
		label.isBordered = false
		label.drawsBackground = false
		label.wantsLayer = true
		label.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
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
