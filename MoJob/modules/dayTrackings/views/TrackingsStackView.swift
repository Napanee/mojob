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

		insertAddButton()

		var endTime: Date?

		for tracking in trackings {
			if let endTime = endTime, tracking.date_start!.timeIntervalSince(endTime) > 60 {
				insertAddButton()
			}

			insertTrackingView(with: tracking)

			endTime = tracking.date_end
		}

		insertAddButton()
	}

	func insertTrackingView(with tracking: Tracking) {
		let trackingView = TrackingItem()
		trackingView.tracking = tracking

		addView(trackingView, in: .bottom)
	}

	func insertAddButton() {
		let addButton = AddButton()
		addView(addButton, in: .bottom)

		addConstraints([
			NSLayoutConstraint(item: addButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 60),
			NSLayoutConstraint(item: addButton, attribute: .trailing, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
		])
	}

}
