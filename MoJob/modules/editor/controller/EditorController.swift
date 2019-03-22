//
//  EditorController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

protocol DateFieldDelegate {
	func getFromMonth() -> Int?
	func getFromYear() -> Int?
	func getUntilMonth() -> Int?
	func getUntilYear() -> Int?
}

class EditorController: NSViewController, DateFieldDelegate, NSTextFieldDelegate {
	var tracking: Tracking!
	var currentValue: String! = ""
	@IBOutlet weak var fromDay: NumberField!
	@IBOutlet weak var fromMonth: NumberField!
	@IBOutlet weak var fromYear: NumberField!
	@IBOutlet weak var fromHour: NumberField!
	@IBOutlet weak var fromMinute: NumberField!
	@IBOutlet weak var untilHour: NumberField!
	@IBOutlet weak var untilMinute: NumberField!
	@IBOutlet weak var untilDay: NumberField!
	@IBOutlet weak var untilMonth: NumberField!
	@IBOutlet weak var untilYear: NumberField!
	@IBOutlet weak var job: NSTextField!
	@IBOutlet weak var task: NSTextField!
	@IBOutlet weak var activity: NSTextField!
	@IBOutlet weak var comment: NSTextField!
	@IBOutlet weak var colorPicker: NSPopUpButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		initColorPicker()

		fromDay.dateDelegate = self
		untilDay.dateDelegate = self

		if let jobString = tracking.job_id ?? tracking.custom_job {
			job.stringValue = jobString
		}

		if let taskString = tracking.task_id {
			task.stringValue = taskString
		}

		if let activityString = tracking.activity_id {
			activity.stringValue = activityString
		}

		if let commentString = tracking.comment {
			comment.stringValue = commentString
		}

		if let dateStart = Calendar.current.date(bySetting: .second, value: 0, of: tracking.date_start!) {
			let day = Calendar.current.component(.day, from: dateStart)
			fromDay.stringValue = String(format: "%02d", day)
			let month = Calendar.current.component(.month, from: dateStart)
			fromMonth.stringValue = String(format: "%02d", month)
			let year = Calendar.current.component(.year, from: dateStart)
			fromYear.stringValue = String(year)

			let hour = Calendar.current.component(.hour, from: dateStart)
			fromHour.stringValue = String(format: "%02d", hour)
			let minute = Calendar.current.component(.minute, from: dateStart)
			fromMinute.stringValue = String(format: "%02d", minute)
		}

		if let dateEnd = Calendar.current.date(bySetting: .second, value: 0, of: tracking.date_end!) {
			let day = Calendar.current.component(.day, from: dateEnd)
			untilDay.stringValue = String(format: "%02d", day)
			let month = Calendar.current.component(.month, from: dateEnd)
			untilMonth.stringValue = String(format: "%02d", month)
			let year = Calendar.current.component(.year, from: dateEnd)
			untilYear.stringValue = String(year)

			let hour = Calendar.current.component(.hour, from: dateEnd)
			untilHour.stringValue = String(format: "%02d", hour)
			let minute = Calendar.current.component(.minute, from: dateEnd)
			untilMinute.stringValue = String(format: "%02d", minute)
		}
	}

	func getFromMonth() -> Int? {
		return Int(fromMonth.stringValue)
	}

	func getFromYear() -> Int? {
		return Int(fromYear.stringValue)
	}

	func getUntilMonth() -> Int? {
		return Int(untilMonth.stringValue)
	}

	func getUntilYear() -> Int? {
		return Int(untilYear.stringValue)
	}

	func controlTextDidEndEditing(_ obj: Notification) {
		guard let textField = obj.object as? NSTextField else { return }

		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY/MM/dd HH:mm"

		if (textField == fromMinute || textField == fromHour || textField == fromDay || textField == fromMonth || textField == fromYear) {
			if let oldDate = tracking.date_start,
				let newDate = formatter.date(from: "\(fromYear.stringValue)/\(fromMonth.stringValue)/\(fromDay.stringValue) \(fromHour.stringValue):\(fromMinute.stringValue)"),
				oldDate.compare(newDate) != .orderedSame
			{
				tracking.date_start = newDate
			}
		}

		if (textField == untilMinute || textField == untilHour || textField == untilDay || textField == untilMonth || textField == untilYear) {
			if let oldDate = tracking.date_end,
				let newDate = formatter.date(from: "\(untilYear.stringValue)/\(untilMonth.stringValue)/\(untilDay.stringValue) \(untilHour.stringValue):\(untilMinute.stringValue)"),
				oldDate.compare(newDate) != .orderedSame
			{
				tracking.date_end = newDate
			}
		}
	}

	private func initColorPicker() {
		let menu = NSMenu()
		let size = NSSize(width: 50, height: 19)

		if let crayons = NSColorList.init(named: "Crayons") {
			for key in crayons.allKeys.filter({
				if
					let color = crayons.color(withKey: $0),
					let red = color.usingColorSpace(.deviceRGB)?.redComponent,
					let green = color.usingColorSpace(.deviceRGB)?.greenComponent,
					let blue = color.usingColorSpace(.deviceRGB)?.blueComponent
				{
					return round(red * 100) != round(green * 100) || round(red * 100) != round(blue * 100)
				}

				return false
			}) {
				let item = NSMenuItem(title: key, action: nil, keyEquivalent: "")
				item.image = swatch(size: size, color: crayons.color(withKey: key) ?? .red)
				menu.addItem(item)
			}
		}

		colorPicker.menu = menu
		colorPicker.imagePosition = .imageOnly
		colorPicker.wantsLayer = true
		colorPicker.selectItem(at: 5)

		let lineWidth: CGFloat = 1
		let posTop = colorPicker.bounds.maxY - (lineWidth / 2)
		let lineColor = NSColor.quaternaryLabelColor.cgColor

		let path = NSBezierPath()
		path.move(to: NSPoint(x: colorPicker.bounds.width, y: posTop))
		path.line(to: NSPoint(x: 0, y: posTop))
		let underscore = CAShapeLayer()
		underscore.strokeColor = lineColor
		underscore.lineWidth = lineWidth
		underscore.path = path.cgPath

		colorPicker.layer?.addSublayer(underscore)
	}

	private func swatch(size: NSSize, color: NSColor) -> NSImage {
		let image = NSImage(size: size)
		image.lockFocus()
		color.drawSwatch(in: NSMakeRect(0, 0, size.width, size.height))
		image.unlockFocus()

		return image
	}

	@IBAction func deleteTracking(_ sender: NSButton) {
		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
		context.delete(tracking)

		do {
			try context.save()
			removeFromParent()
		} catch let error {
			print(error)
		}
	}
	
	@IBAction func cancel(_ sender: NSButton) {
		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
		context.refresh(tracking, mergeChanges: false)
		removeFromParent()
	}

	@IBAction func save(_ sender: NSButton) {
		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext

		do {
			try context.save()
			removeFromParent()
		} catch let error {
			print(error)
		}
	}

}
