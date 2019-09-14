//
//  TrackingsStackView.swift
//  MoJob
//
//  Created by Martin Schneider on 10.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingsStackView: NSStackView {

	var currentDate: Date = Date()

	func reloadData(with trackings: [Tracking]) {
		subviews.removeAll()

		var endTime: Date = currentDate.startOfDay!

		for tracking in trackings {
			if tracking.date_start!.timeIntervalSince(endTime) > 60 {
				insertAddButton(from: endTime, until: tracking.date_start!)
			}

			insertTrackingView(with: tracking)

			endTime = tracking.date_end ?? Date()
		}

		if (Calendar.current.isDateInToday(endTime)) {
			insertAddButton(from: endTime)
		} else {
			insertAddButton(from: endTime, until: endTime.endOfDay)
		}
	}

	func insertTrackingView(with tracking: Tracking) {
		let trackingView = TrackingItem()
		trackingView.tracking = tracking

		if let syncStatus = SyncStatus(rawValue: tracking.exported ?? "error"), tracking.date_end != nil {
			trackingView.exportStatus = syncStatus
		}

		addView(trackingView, in: .bottom)
	}

	func insertAddButton(from: Date, until: Date? = nil) {
		let addButton = AddButton()
		addButton.from = from
		addButton.until = until
		addView(addButton, in: .bottom)

		addConstraints([
			NSLayoutConstraint(item: addButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 50),
			NSLayoutConstraint(item: addButton, attribute: .trailing, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
		])
	}

}
