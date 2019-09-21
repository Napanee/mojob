//
//  StatsViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 16.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa
import Charts

struct TrackingSet {
	var id: String
	var title: String
	var date: Date
	var color: String?
	var duration: TimeInterval
}


class StatsViewController: NSViewController {

	@IBOutlet weak var pieChart: PieChartView!
	@IBOutlet weak var barChart: BarChartView!
	@IBOutlet weak var pieChartLegendView: NSStackView!
	@IBOutlet weak var nextMonthButton: NSButton!
	@IBOutlet weak var nextYearButton: NSButton!
	@IBOutlet weak var currentMonth: NSTextField!
	@IBOutlet weak var todayButton: NSButton!
	@IBOutlet weak var sumMonthLabel: NSTextField!

	let animationDuration = 0.5
	let formatter = DateComponentsFormatter()
	var calendar = Calendar.current
	var labelText: String = ""

	var daysRange: CountableRange<Int> = Calendar.current.range(of: .day, in: .month, for: Date()) ?? 1..<30
	var weekDaysCount: Int = 20
	var trackingSet: [TrackingSet] = []
	var sumMonth: Double = 0

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
			weekDaysCount = daysRange.filter({ day -> Bool in
				var comp = calendar.dateComponents([.year, .month, .day], from: newValue)
				comp.day = day

				return !calendar.isDateInWeekend(calendar.date(from: comp)!)
			}).count
			if let trackings = CoreDataHelper.trackings(from: newValue.startOfMonth!, byAdding: .month) {
				trackingSet = trackings.map({ tracking in
					var title = "Custom"

					if let job = tracking.job {
						title = job.fullTitle
					} else if let customJob = tracking.custom_job {
						title = customJob
					} else if let activity = tracking.activity, let activityTitle = activity.title {
						title = activityTitle
					}

					return TrackingSet(id: tracking.job?.id ?? "custom", title: title, date: tracking.date_start!, color: tracking.job?.color, duration: tracking.duration)
				})
			}

			barChartUpdate()
			pieChartUpdate()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		todayButton.wantsLayer = true
		todayButton.layer?.borderWidth = 1
		todayButton.layer?.cornerRadius = 16
		todayButton.layer?.borderColor = NSColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 0.7).cgColor

		calendar.locale = Locale(identifier: "de")
		formatter.calendar = calendar
		formatter.zeroFormattingBehavior = .pad
		formatter.allowedUnits = [.hour, .minute]

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

// MARK: - PieChart Setup

extension StatsViewController {

	func pieChartPrepareData() -> [PieChartDataEntry] {
		var trackingSetMerged: [TrackingSet] = []
		trackingSet.forEach { item in
			let sum = trackingSet
				.filter({ $0.id == item.id })
				.reduce(0.0, { $0 + $1.duration })
			var updatedItem = item
			updatedItem.duration = sum
			let obj = updatedItem

			if (!trackingSetMerged.contains(where: { $0.id == obj.id })) {
				trackingSetMerged += [obj]
			}
		}

		var dataEntries: [PieChartDataEntry] = []
		for item in trackingSetMerged.sorted(by: { $0.duration > $1.duration }) {
			let dataEntry = PieChartDataEntry(value: item.duration, label: item.title, data: item)
			dataEntries.append(dataEntry)
		}

		return dataEntries
	}

	func pieChartUpdate() {
		let pieChartData = pieChartPrepareData()
		var colors: [NSColor] = []
		let path = Bundle.main.path(forResource: "MoJob", ofType: "clr")
		let colorList = NSColorList(name: "MoJob", fromFile: path)
		pieChartData.forEach({ dataEntry in
			if let trackingSet = dataEntry.data as? TrackingSet,
				let jobColor = trackingSet.color,
				let color = colorList?.color(withKey: jobColor) {

				colors.append(color)
			} else {
				let red = Double(arc4random_uniform(256))
				let green = Double(arc4random_uniform(256))
				let blue = Double(arc4random_uniform(256))

				let color = NSColor(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
				colors.append(color)
			}
		})

		let chartDataSet = PieChartDataSet(entries: pieChartData, label: nil)
		chartDataSet.colors = colors
		chartDataSet.valueColors = colors
		chartDataSet.valueFormatter = self
		chartDataSet.sliceSpace = 2.0
		chartDataSet.drawValuesEnabled = false
		chartDataSet.selectionShift = 0.0

		formatter.unitsStyle = .abbreviated
		let actualHours = formatter.string(from: sumMonth) ?? "0h 0m"
		formatter.zeroFormattingBehavior = [.dropAll]
		let targetHours = formatter.string(from: Double(weekDaysCount * 8 * 3600)) ?? "0h 0m"
		let paragraph = NSMutableParagraphStyle()
		paragraph.alignment = .center
		let centerText = NSMutableAttributedString()
		let actualHoursText = NSMutableAttributedString(
			string: actualHours,
			attributes: [
				NSAttributedString.Key.foregroundColor: NSColor.black,
				NSAttributedString.Key.font: NSFont.systemFont(ofSize: 22, weight: .ultraLight),
				NSAttributedString.Key.paragraphStyle: paragraph
			])
		let targetHoursText = NSMutableAttributedString(
			string: "\n von \(targetHours)",
			attributes: [
				NSAttributedString.Key.foregroundColor: NSColor.black,
				NSAttributedString.Key.font: NSFont.systemFont(ofSize: 16, weight: .light),
				NSAttributedString.Key.paragraphStyle: paragraph
			])
		centerText.append(actualHoursText)
		centerText.append(targetHoursText)
		pieChart.centerAttributedText = centerText
//		pieChart.marker = self
		pieChart.legend.enabled = false
		pieChart.drawEntryLabelsEnabled = false
		pieChart.holeRadiusPercent = 0.7

		pieChart.data = PieChartData(dataSet: chartDataSet)

		renderLegend(with: pieChart.legend.entries)

		pieChart.animate(yAxisDuration: animationDuration, easingOption: .easeInOutQuad)
	}

	func renderLegend(with entries: [LegendEntry]) {
		let entryAnimationDuration = animationDuration / Double(entries.count)

		pieChartLegendView.subviews.removeAll()

		entries.enumerated().forEach { (i, entry) in
			let label = LegendLabel(labelWithString: entry.label!)
			label.usesSingleLineMode = false
			label.cell?.wraps = true
			label.cell?.isScrollable = false
			label.cell?.usesSingleLineMode = false
			label.lineBreakMode = .byWordWrapping
			label.font = NSFont.systemFont(ofSize: 11, weight: .light)
			label.color = entry.formColor
			label.alphaValue = 0

			pieChartLegendView.addView(label, in: .bottom)
			pieChartLegendView.addConstraint(
				NSLayoutConstraint(
					item: label,
					attribute: .width,
					relatedBy: .equal,
					toItem: label.superview,
					attribute: .width,
					multiplier: 1,
					constant: 0
				)
			)

			DispatchQueue.main.asyncAfter(deadline: .now() + (entryAnimationDuration * Double(i))) {
				NSAnimationContext.runAnimationGroup({ context in
					context.duration = 0.5
					label.animator().alphaValue = 1
				}, completionHandler: nil)
			}
		}
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

		formatter.unitsStyle = .full
		sumMonthLabel.stringValue = formatter.string(from: sumMonth) ?? "0h 0m"

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

		barChart.animate(yAxisDuration: animationDuration, easingOption: .easeInOutQuad)
	}

}

extension StatsViewController: IMarker {

	var offset: CGPoint {
		return CGPoint(x: 0, y: 0)
	}

	func offsetForDrawing(atPoint: CGPoint) -> CGPoint {
		return CGPoint(x: 0, y: 0)
	}

	func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
		labelText = "foo"
	}

	func draw(context: CGContext, point: CGPoint) {
		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = .center
		let attrs: [NSAttributedString.Key: AnyObject] = [.font: NSFont.systemFont(ofSize: 10.0, weight: .light), .paragraphStyle: paragraphStyle, .foregroundColor: NSColor.red, .baselineOffset: NSNumber(value: -4)]

		// custom padding around text
		let labelWidth = labelText.size(withAttributes: attrs).width + 10
		// if you modify labelHeigh you will have to tweak baselineOffset in attrs
		let labelHeight = labelText.size(withAttributes: attrs).height + 4

		// place pill above the marker, centered along x
		var rectangle = CGRect(x: point.x, y: point.y, width: labelWidth, height: labelHeight)
		rectangle.origin.x -= rectangle.width / 2.0
		let spacing: CGFloat = 20
		rectangle.origin.y -= rectangle.height + spacing

		// rounded rect
//		let clipPath = UIBezierPath(roundedRect: rectangle, cornerRadius: 6.0).cgPath
		let clipPath = NSBezierPath(roundedRect: rectangle, xRadius: 6.0, yRadius: 6.0).cgPath
		context.addPath(clipPath)
		context.setFillColor(NSColor.white.cgColor)
		context.setStrokeColor(NSColor.black.cgColor)
		context.closePath()
		context.drawPath(using: .fillStroke)

		// add the text
		labelText.draw(with: rectangle, options: .usesLineFragmentOrigin, attributes: attrs, context: nil)
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
		formatter.zeroFormattingBehavior = [.pad, .dropLeading, .dropTrailing]

		if (entry.isKind(of: PieChartDataEntry.self)) {
			if let data = entry.data as? TrackingSet {
				formatter.allowedUnits = [.day, .hour, .minute]
				formatter.unitsStyle = .abbreviated
				formatter.maximumUnitCount = 2
				return formatter.string(from: data.duration) ?? String(value)
			}
		} else if (entry.isKind(of: BarChartDataEntry.self)) {
			formatter.allowedUnits = [.hour, .minute]
			formatter.unitsStyle = .positional
			return formatter.string(from: entry.data as? TimeInterval ?? 0) ?? String(value)
		}

		return String(value)
	}

}
