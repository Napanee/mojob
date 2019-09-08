//
//  NumberField.swift
//  MoJob
//
//  Created by Martin Schneider on 10.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class NumberField: TextField {

	var dateDelegate: DateFieldDelegate?
	var currentValue: String! = ""

	override func textDidBeginEditing(_ notification: Notification) {
		super.textDidBeginEditing(notification)
		currentValue = self.stringValue
	}

	override func textDidEndEditing(_ notification: Notification) {
		super.textDidEndEditing(notification)

		guard var value = Int(self.stringValue) else {
			self.stringValue = self.currentValue
			return
		}

		switch (identifier?.rawValue) {
		case "fromMonth", "untilMonth":
			value = max(min(12, value), 1)
			break
		case "fromHour", "untilHour":
			value = max(min(23, value), 0)
			break
		case "fromMinute", "untilMinute":
			value = max(min(59, value), 0)
			break
		case "fromDay":
			guard let delegate = dateDelegate, let year = delegate.getFromYear(), let month = delegate.getFromMonth() else { break }
			value = max(min(maxDays(month: month, year: year), value), 1)
			break
		default:
			break
		}

		self.stringValue = String(format: "%02d", value)
	}

}
