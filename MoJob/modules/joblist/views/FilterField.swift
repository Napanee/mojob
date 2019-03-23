//
//  FilterField.swift
//  MoJob
//
//  Created by Martin Schneider on 09.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class FilterField: TextField, NSTextFieldDelegate {

	var customDelegate: FilterFieldDelegate?
	var keyDownEventMonitor: Any?

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	override func mouseDown(with event: NSEvent) {
		super.mouseDown(with: event)

		if (keyDownEventMonitor == nil) {
			keyDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown, handler: keyDownEvent)
		}
	}

	override func textShouldBeginEditing(_ textObject: NSText) -> Bool {
		super.textShouldBeginEditing(textObject)

		if (keyDownEventMonitor == nil) {
			keyDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown, handler: keyDownEvent)
		}

		return true
	}

	override func textDidChange(_ notification: Notification) {
		super.textDidChange(notification)

		guard let textView = notification.object as? NSTextView else { return }

		customDelegate?.onTextChange(with: textView.string)
	}

	override func textDidEndEditing(_ notification: Notification) {
		super.textDidEndEditing(notification)

		if let keyDownEventMonitor = keyDownEventMonitor {
			NSEvent.removeMonitor(keyDownEventMonitor)
			self.keyDownEventMonitor = nil
		}
	}

	private func keyDownEvent(event: NSEvent) -> NSEvent? {
		customDelegate?.onKeyDown(keyCode: event.keyCode)

		if ([125, 126, 36].contains(event.keyCode)) {
			return nil
		}

		return event
	}

}
