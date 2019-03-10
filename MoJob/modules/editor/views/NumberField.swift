//
//  NumberField.swift
//  MoJob
//
//  Created by Martin Schneider on 10.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class NumberField: NSTextField {

	var dateDelegate: DateFieldDelegate?
	var currentValue: String! = ""

	override func textDidBeginEditing(_ notification: Notification) {
		super.textDidBeginEditing(notification)
		currentValue = self.stringValue
	}

	override func textDidChange(_ notification: Notification) {
		super.textDidChange(notification)
		print(self.stringValue)
	}

	override func textDidEndEditing(_ notification: Notification) {
		super.textDidEndEditing(notification)
		guard var value = Int(self.stringValue) else {
			self.stringValue = self.currentValue
			return
		}

		switch (identifier?.rawValue) {
		case "fromMonth", "untilMonth":
			value = min(12, value)
			break
		case "fromHour", "untilHour":
			value = min(23, value)
			break
		case "fromMinute", "untilMinute":
			value = min(59, value)
			break
		case "fromDay":
			guard
				let delegate = dateDelegate,
				let year = delegate.getFromYear(),
				let month = delegate.getFromMonth() else
			{
				break
			}
			value = min(maxDays(month: month, year: year), value)
			break
		case "untilDay":
			guard
				let delegate = dateDelegate,
				let year = delegate.getUntilYear(),
				let month = delegate.getUntilMonth() else
			{
				break
			}
			value = min(maxDays(month: month, year: year), value)
			break
		default:
			break
		}

		self.stringValue = String(format: "%02d", value)
	}

}
