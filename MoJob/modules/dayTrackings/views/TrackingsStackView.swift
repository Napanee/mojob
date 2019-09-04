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

		if let date = currentDate.compare(endTime) == .orderedSame ? currentDate.endOfDay : Date(), let until = Calendar.current.date(byAdding: .minute, value: -1, to: date) {
			insertAddButton(from: endTime, until: Calendar.current.date(bySetting: .second, value: 0, of: until)!)
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
