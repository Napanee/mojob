//
//  TrackingsStackView.swift
//  MoJob
//
//  Created by Martin Schneider on 10.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingsStackView: NSStackView {

	func reloadData(with trackings: [Tracking]) {
		subviews.removeAll()

		var endTime: Date = Date().startOfDay!

		for tracking in trackings {
			if tracking.date_start!.timeIntervalSince(endTime) > 60 {
				insertAddButton(from: endTime, until: tracking.date_start!)
			}

			insertTrackingView(with: tracking)

			endTime = tracking.date_end!
		}

		insertAddButton(from: endTime, until: Calendar.current.date(bySetting: .second, value: 0, of: Date())!)
	}

	func insertTrackingView(with tracking: Tracking) {
		let trackingView = TrackingItem()
		trackingView.tracking = tracking

		if let syncStatus = SyncStatus(rawValue: tracking.exported ?? "error") {
			trackingView.exportStatus = syncStatus
		}

		addView(trackingView, in: .bottom)
	}

	func insertAddButton(from: Date, until: Date) {
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
