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
	@IBOutlet weak var jobWrapper: NSView!
	@IBOutlet weak var taskWrapper: NSView!
	@IBOutlet weak var activityWrapper: NSView!
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
	@IBOutlet weak var jobComboBox: NSComboBox!
	@IBOutlet weak var taskComboBox: NSComboBox!
	@IBOutlet weak var activityComboBox: NSComboBox!
	@IBOutlet weak var comment: NSTextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		fromDay.dateDelegate = self
		untilDay.dateDelegate = self

		jobWrapper.addSubview(jobComboBox, positioned: .below, relativeTo: job)
		taskWrapper.addSubview(taskComboBox, positioned: .below, relativeTo: task)
		activityWrapper.addSubview(activityComboBox, positioned: .below, relativeTo: activity)

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
