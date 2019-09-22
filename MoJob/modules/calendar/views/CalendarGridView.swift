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
	private let formatter = DateComponentsFormatter()
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

		formatter.unitsStyle = .positional
		formatter.zeroFormattingBehavior = .pad
		formatter.allowedUnits = [.hour, .minute]

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

		var gridRow: [NSView] = []
		var day = calendar.date(from: month)
		var evenWeekDays = userDefaults.array(forKey: UserDefaults.Keys.evenWeekDays) as? [Int] ?? []
		evenWeekDays = evenWeekDays + [6, 7] // add saturday and sunday
		var oddWeekDays = userDefaults.array(forKey: UserDefaults.Keys.oddWeekDays) as? [Int] ?? []
		oddWeekDays = oddWeekDays + [6, 7] // add saturday and sunday
		let evenWeekHours = userDefaults.integer(forKey: UserDefaults.Keys.evenWeekHours)
		let evenWorkHours = Double(evenWeekHours) / Double(7 - evenWeekDays.count) * 3600
		let oddWeekHours = userDefaults.integer(forKey: UserDefaults.Keys.oddWeekHours)
		let oddWorkHours = Double(oddWeekHours) / Double(7 - oddWeekDays.count) * 3600

		let weeksInMonth = calendar.range(of: .weekOfYear, in: .month, for: calendar.date(from: month)!)
		for w in weeksInMonth! {
			var week = month
			week.weekOfYear = w
			week.weekday = 2

			day = calendar.date(from: week)
			let hoursForWeek = CoreDataHelper.seconds(from: (day?.startOfWeek)!, byAdding: .weekOfMonth, and: job) ?? 0
			let weekNumber = calendar.component(.weekOfYear, from: day!)
			let isEvenWeek = (weekNumber % 2) == 0
			let missingHoursInWeek = (isEvenWeek && hoursForWeek - Double(evenWeekHours) * 3600 < 0) || (!isEvenWeek && hoursForWeek - Double(oddWeekHours) * 3600 < 0)

			let content = CalendarWeek()
			content.weekLabel.stringValue = String(weekNumber)
			content.timeLabel.stringValue = formatter.string(from: hoursForWeek)!

			gridRow = [content]

			for d in 2...8 { // little hack, to start with monday, instead of sunday
				week.weekday = d < 8 ? d : 1
				day = calendar.date(from: week)

				let isFreeDay = isEvenWeek && evenWeekDays.contains(d - 1) || !isEvenWeek && oddWeekDays.contains(d - 1)
				let hoursForDay = CoreDataHelper.seconds(from: (day?.startOfDay)!, byAdding: .day, and: job) ?? 0

				let content = CalendarDay()
				content.delegate = self
				content.day = day
				content.isCurrentMonth = calendar.date(day!, matchesComponents: month)
				content.isFreeDay = isFreeDay
				content.missingHours = day?.compare(Date()) == ComparisonResult.orderedAscending && missingHoursInWeek && !isFreeDay && ((isEvenWeek && hoursForDay - evenWorkHours < 0) || (!isEvenWeek && hoursForDay - oddWorkHours < 0))
				content.timeLabel.stringValue = formatter.string(from: hoursForDay)!

				gridRow.append(content)
			}

			addRow(with: gridRow)
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
