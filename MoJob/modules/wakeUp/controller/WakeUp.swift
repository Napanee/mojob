//
//  WakeUp.swift
//  MoJob
//
//  Created by Martin Schneider on 08.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


class WakeUp: NSViewController {

	var sleepTime: Date?
	var radioButtons: [NSButton] = []

	@IBOutlet weak var descriptionText: NSTextField!
	@IBOutlet weak var appIcon: NSImageView!
	@IBOutlet weak var radioDoNothing: NSButton!
	@IBOutlet weak var radioStopNow: NSButton!
	@IBOutlet weak var radioTimerStop: NSButton!
	@IBOutlet weak var radioTimerStopAndStartNew: NSButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		appIcon.image = NSApp.applicationIconImage

		radioButtons = [radioDoNothing, radioStopNow, radioTimerStop, radioTimerStopAndStartNew]

		view.wantsLayer = true
		view.layer?.backgroundColor = NSColor.white.cgColor
	}

	override func viewDidAppear() {
		guard let sleepTime = sleepTime else { return }

		let formatter = DateFormatter()
		formatter.dateFormat = "HH:mm"
		let dateString = formatter.string(from: sleepTime)

		descriptionText.stringValue = descriptionText.stringValue.replacingOccurrences(of: "%time%", with: dateString)
		radioTimerStop.title = radioTimerStop.title.replacingOccurrences(of: "%time%", with: dateString)
		radioTimerStopAndStartNew.title = radioTimerStopAndStartNew.title.replacingOccurrences(of: "%time%", with: dateString)

		let pstyle = NSMutableParagraphStyle()
		pstyle.firstLineHeadIndent = 5.0
		for button in radioButtons {
			button.attributedTitle = NSAttributedString(
				string: button.title,
				attributes: [
					NSAttributedString.Key.paragraphStyle: pstyle
				]
			)
		}

		if let window = view.window {
			window.styleMask = NSWindow.StyleMask.fullSizeContentView
			window.isMovableByWindowBackground = true

			window.standardWindowButton(.closeButton)?.isHidden = true
			window.standardWindowButton(.miniaturizeButton)?.isHidden = true
			window.standardWindowButton(.zoomButton)?.isHidden = true
		}
	}

	@IBAction func radioHandleTracking(_ sender: NSButton) {
		radioButtons.filter({ $0 !== sender }).forEach { $0.state = .off }
	}

	@IBAction func confirm(_ sender: NSButton) {
		guard
			let selectedChoice = radioButtons.first(where: { $0.state == .on }),
			let currentTracking = CoreDataHelper.currentTracking
		else { return }

		switch selectedChoice.tag {
		case 2: // stop timer before sleep
			currentTracking.stop(dateEnd: sleepTime)
			break
		case 3: // stop timer and start new tracking
			currentTracking.stop(dateEnd: sleepTime)
			break
		case 4: // stop timer now
			currentTracking.stop()
			break
		default:
			break
		}

		if ([2, 4].contains(selectedChoice.tag)) {

		}

		dismiss(self)
	}

}
