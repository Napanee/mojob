//
//  EditorController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class EditorController: NSViewController, NSTextFieldDelegate {

	var tracking: Tracking!
	var currentValue: String! = ""
	@IBOutlet weak var jobWrapper: NSView!
	@IBOutlet weak var fromDay: NSTextField!
	@IBOutlet weak var fromMonth: NSTextField!
	@IBOutlet weak var fromYear: NSTextField!
	@IBOutlet weak var fromHour: NSTextField!
	@IBOutlet weak var fromMinute: NSTextField!
	@IBOutlet weak var untilHour: NSTextField!
	@IBOutlet weak var untilMinute: NSTextField!
	@IBOutlet weak var untilDay: NSTextField!
	@IBOutlet weak var untilMonth: NSTextField!
	@IBOutlet weak var untilYear: NSTextField!

	override func viewDidLoad() {
		super.viewDidLoad()

		fromDay.delegate = self
		fromMonth.delegate = self
		fromYear.delegate = self
		fromHour.delegate = self
		fromMinute.delegate = self
		untilHour.delegate = self
		untilMinute.delegate = self
		untilDay.delegate = self
		untilMonth.delegate = self
		untilYear.delegate = self

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

	func controlTextDidBeginEditing(_ obj: Notification) {
		if let textField = obj.object as? NSTextField {
			currentValue = textField.stringValue
		}
	}

	func controlTextDidChange(_ obj: Notification) {
		if let textField = obj.object as? NSTextField {
			print(textField.stringValue)
		}
	}

	func controlTextDidEndEditing(_ obj: Notification) {
		guard let textField = obj.object as? NSTextField else { return }
		guard var value = Int(textField.stringValue) else {
			textField.stringValue = self.currentValue
			return
		}

		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY/MM/dd HH:mm"

		switch true {
		case textField == fromMonth || textField == untilMonth:
			value = min(12, value)
			break
		case textField == fromDay:
			guard let year = Int(fromYear.stringValue), let month = Int(fromMonth.stringValue) else {
				break
			}
			value = min(maxDays(month: month, year: year), value)
			break
		case textField == untilDay:
			guard let year = Int(untilYear.stringValue), let month = Int(untilMonth.stringValue) else {
				break
			}
			value = min(maxDays(month: month, year: year), value)
			break
		case textField == fromHour || textField == untilHour:
			value = min(23, value)
			break
		case textField == fromMinute || textField == untilMinute:
			value = min(59, value)
			break
		default:
			break
		}

		textField.stringValue = String(format: "%02d", value)

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

	@IBAction func deleteTracking(_ sender: NSButton) {
		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
		context.delete(tracking)

		do {
			try context.save()
		} catch let error {
			print(error)
		}
	}
	
	@IBAction func cancel(_ sender: NSButton) {
		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
		context.refresh(tracking, mergeChanges: false)
	}

	@IBAction func save(_ sender: NSButton) {
		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext

		do {
			try context.save()
		} catch let error {
			print(error)
		}
	}

}
