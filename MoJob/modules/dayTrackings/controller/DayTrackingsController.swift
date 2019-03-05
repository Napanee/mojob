//
//  DayTrackingsController.swift
//  MoJob
//
//  Created by Martin Schneider on 23.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class DayTrackingsController: NSViewController {

	@IBOutlet weak var dateDay: NSTextField!
	@IBOutlet weak var dateMonth: NSTextField!
	@IBOutlet weak var dateYear: NSTextField!
	@IBOutlet weak var totalTimeForDay: NSTextField!
	@IBOutlet weak var trackingsStackView: NSStackView!

	@IBOutlet weak var btn: NSButton!
	struct Tracking {
		var id: String
		var start: Date
		var end: Date
		var job: String
		var text: String? = nil

		init(id: String, start: Date, end: Date, job: String) {
			self.id = id
			self.start = start
			self.end = end
			self.job = job
		}

		init(id: String, start: Date, end: Date, job: String, text: String) {
			self.id = id
			self.start = start
			self.end = end
			self.job = job
			self.text = text
		}
	}

	var trackings: [Tracking]! = []

	override func viewDidLoad() {
		super.viewDidLoad()

		dateDay.stringValue = Date().day
		dateMonth.stringValue = Date().month
		dateYear.stringValue = Date().year

		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy/MM/dd HH:mm"
		let startDate1 = formatter.date(from: "2019/02/24 10:02")
		let endDate1 = formatter.date(from: "2019/02/24 10:58")
		trackings.append(Tracking(id: "lor-2747", start: startDate1!, end: endDate1!, job: "foo", text: "1 Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero "))

		let startDate2 = formatter.date(from: "2019/02/24 11:30")
		let endDate2 = formatter.date(from: "2019/02/24 12:42")
		trackings.append(Tracking(id: "lor-2747", start: startDate2!, end: endDate2!, job: "lor2026 - Loreal Maintanance with more text to longer long long"))

		let startDate3 = formatter.date(from: "2019/02/24 12:43")
		let endDate3 = formatter.date(from: "2019/02/24 14:42")
		trackings.append(Tracking(id: "int-2214", start: startDate3!, end: endDate3!, job: "foo bazzz"))


		let formatter2 = DateFormatter()
		formatter2.dateFormat = "HH:mm"

		var endTime: Date?

		for tracking in trackings {
			let trackingView = TrackingItem()

			trackingsStackView.addView(trackingView, in: .bottom)
			trackingView.startTimeLabel.stringValue = formatter2.string(from: tracking.start)
			trackingView.titleLabel.stringValue = tracking.job

			if let text = tracking.text {
				print(text)
				trackingView.commentLabel.stringValue = text
			} else {
				trackingView.commentLabel.removeFromSuperview()
				print(trackingView.titleLabel.constraints)

				if let superview = trackingView.titleLabel.superview {
					let constraint = NSLayoutConstraint(item: superview, attribute: .bottom, relatedBy: .equal, toItem: trackingView.titleLabel, attribute: .bottom, multiplier: 1, constant: 5)
					superview.addConstraint(constraint)
				}
			}

			trackingView.setContentHuggingPriority(NSLayoutConstraint.Priority(rawValue: 250), for: NSLayoutConstraint.Orientation.horizontal)
			trackingView.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(750), for: NSLayoutConstraint.Orientation.horizontal)
			trackingsStackView.addConstraint(NSLayoutConstraint(item: trackingView, attribute: .width, relatedBy: .equal, toItem: trackingView.superview, attribute: .width, multiplier: 1, constant: 0))

			if let endTime = endTime, tracking.start.timeIntervalSince(endTime) > 60 {
				print(tracking.job)
				print(tracking.start.timeIntervalSince(endTime))
				let addButtonBeforeAll = NSButton()
				addButtonBeforeAll.title = "add"
				addButtonBeforeAll.isBordered = false
				addButtonBeforeAll.wantsLayer = true
				addButtonBeforeAll.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
				addButtonBeforeAll.translatesAutoresizingMaskIntoConstraints = false
				addButtonBeforeAll.addConstraint(NSLayoutConstraint(item: addButtonBeforeAll, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 30))

				trackingsStackView.addView(addButtonBeforeAll, in: NSStackView.Gravity.bottom)

				let buttonContraints = [
					NSLayoutConstraint(item: addButtonBeforeAll, attribute: .trailing, relatedBy: .equal, toItem: addButtonBeforeAll.superview, attribute: .trailing, multiplier: 1, constant: 0),
					NSLayoutConstraint(item: addButtonBeforeAll, attribute: .leading, relatedBy: .equal, toItem: addButtonBeforeAll.superview, attribute: .leading, multiplier: 1, constant: 60)
				]
				view.addConstraints(buttonContraints)
			}

			endTime = tracking.end
		}

		print(trackingsStackView.constraints)
//
//		print(innerClipView.bounds)
//		print(clipView.bounds)
	}

}
