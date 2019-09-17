//
//  StatsViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 16.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa
import Charts


class StatsViewController: NSViewController {

	@IBOutlet weak var pieChart: PieChartView!
	@IBOutlet weak var barChart: BarChartView!
	@IBOutlet weak var nextMonthButton: NSButton!
	@IBOutlet weak var nextYearButton: NSButton!
	@IBOutlet weak var currentMonth: NSTextField!
	@IBOutlet weak var todayButton: NSButton!
	@IBOutlet weak var sumMonthLabel: NSTextField!

	var calendar = Calendar.current

	var daysRange: CountableRange<Int> = Calendar.current.range(of: .day, in: .month, for: Date()) ?? 1..<30
	var trackingSet: [(date: Date, color: String?, duration: TimeInterval)] = []
	var sumMonth: Double {
		get {
			return 0
		}
		set {
			calendar.locale = Locale(identifier: "de")
			let formatter = DateComponentsFormatter()
			formatter.calendar = calendar
			formatter.unitsStyle = .full
			formatter.zeroFormattingBehavior = .pad
			formatter.allowedUnits = [.hour, .minute]

			sumMonthLabel.stringValue = formatter.string(from: newValue) ?? "0h 0m"
		}
	}

	var _currentDate: Date = Date()
	var currentDate: Date {
		get {
			return _currentDate
		}
		set {
			_currentDate = newValue

			let components = calendar.dateComponents([.month, .year], from: newValue)
			currentMonth.stringValue = "\(calendar.monthSymbols[components.month! - 1]) \(components.year!)"

			let isCurrentMonth = calendar.isDate(Date(), equalTo: newValue, toGranularity: .month)
			nextMonthButton.isEnabled = !isCurrentMonth
			nextYearButton.isEnabled = !isCurrentMonth

			daysRange = calendar.range(of: .day, in: .month, for: newValue) ?? 1..<30
			if let trackings = CoreDataHelper.trackings(from: newValue.startOfMonth!, byAdding: .month) {
				trackingSet = trackings.map({ (date: $0.date_start!, color: $0.job?.color, duration: $0.duration) })
			}

			barChartUpdate()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		todayButton.wantsLayer = true
		todayButton.layer?.borderWidth = 1
		todayButton.layer?.cornerRadius = 16
		todayButton.layer?.borderColor = NSColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 0.7).cgColor

		currentDate = Date()
	}

	@IBAction func prevMonthButton(_ sender: NSButton) {
		currentDate = calendar.date(byAdding: .month, value: -1, to: currentDate)!
	}

	@IBAction func nextMonthButton(_ sender: NSButton) {
		currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
	}

	@IBAction func prevYearButton(_ sender: NSButton) {
		currentDate = calendar.date(byAdding: .year, value: -1, to: currentDate)!
	}

	@IBAction func nextYearButton(_ sender: NSButton) {
		let nextDate = calendar.date(byAdding: .year, value: 1, to: currentDate)!
		currentDate = nextDate.compare(Date()) == ComparisonResult.orderedAscending ? nextDate : Date()
	}

	@IBAction func todayButton(_ sender: NSButton) {
		currentDate = Date()
	}

}

// MARK: - BarChart Setup

extension StatsViewController {

	func barChartPrepareData() -> [BarChartDataEntry] {
		var dataEntries: [BarChartDataEntry] = []
		var totalSum: Double = 0

		for i in daysRange {
			var hours: Double = 0

			var comp = calendar.dateComponents([.year, .month, .day], from: currentDate)
			comp.day = i

			guard let day = calendar.date(from: comp) else { continue }

			let sum = trackingSet
				.filter({ calendar.compare(day, to: $0.date, toGranularity: .day) == ComparisonResult.orderedSame })
				.map({ $0.duration })
				.reduce(0, +)
			hours = Double(round(10 * (sum / 3600)) / 10)

			if (hours > 0) {
				let dataEntry = BarChartDataEntry(x: Double(i - 1), y: hours, data: sum)
				dataEntries.append(dataEntry)
			}

			totalSum += sum
		}

		sumMonth = totalSum

		return dataEntries
	}

	func barChartSetup() {
		barChart.legend.enabled = false
		barChart.getAxis(.right).enabled = false

		let xAxis = barChart.xAxis
		xAxis.drawGridLinesEnabled = false
		xAxis.valueFormatter = self
		xAxis.labelCount = daysRange.count
		xAxis.axisMaxLabels = .max
		xAxis.labelTextColor = NSColor.secondaryLabelColor
		xAxis.labelPosition = .bottom
		xAxis.labelFont = NSFont.systemFont(ofSize: 12.0, weight: .light)
		xAxis.axisMinimum = -0.5
		xAxis.axisMaximum = Double(daysRange.count) - 0.5

		let left = barChart.getAxis(.left)
		left.gridColor = NSColor.tertiaryLabelColor
		left.valueFormatter = self
		left.drawAxisLineEnabled = false
		left.axisMinimum = 0
		left.labelTextColor = NSColor.secondaryLabelColor
		left.labelFont = NSFont.systemFont(ofSize: 10, weight: .light)

		let ll = ChartLimitLine(limit: 8.0)
		ll.lineWidth = 1.5
		left.addLimitLine(ll)
	}

	func barChartUpdate() {
		let chartDataSet = BarChartDataSet(entries: barChartPrepareData(), label: nil)
		if #available(OSX 10.14, *) {
			chartDataSet.colors = [NSColor.controlAccentColor]
		} else {
			chartDataSet.colors = [NSColor(calibratedRed: 0.063, green: 0.475, blue: 0.988, alpha: 1.0)]
		}
		chartDataSet.valueFont = NSFont.systemFont(ofSize: 10, weight: .semibold)
		chartDataSet.valueFormatter = self

		barChart.data = BarChartData(dataSet: chartDataSet)
		barChartSetup()

		barChart.animate(yAxisDuration: 1.0, easingOption: .easeInOutQuad)
	}

}

// MARK: - ChartDelegate, ValueFormatters

extension StatsViewController: ChartViewDelegate, IAxisValueFormatter, IValueFormatter {

	func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {

	}

	func stringForValue(_ value: Double, axis: AxisBase?) -> String {
		if let axis = axis, barChart.getAxis(.left).isEqual(axis) {
			return "\(Int(value))h"
		}

		return String(Int(value + 1))
	}

	func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .positional
		formatter.zeroFormattingBehavior = .pad
		formatter.allowedUnits = [.hour, .minute]

		return formatter.string(from: entry.data as? TimeInterval ?? 0) ?? String(value)
	}

}
