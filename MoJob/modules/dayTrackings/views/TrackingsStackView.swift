//
//  TrackingsStackView.swift
//  MoJob
//
//  Created by Martin Schneider on 10.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingsStackView: NSStackView {

	private func timeStartForItem(at index: Int) -> Date? {
		guard index >= 0 else { return nil }
		guard index < subviews.count else { return nil }

		if let trackingItem = subviews[index] as? TrackingItem {
			return trackingItem.tracking?.date_start
		}

		return nil
	}

	private func timeEndForItem(at index: Int) -> Date? {
		guard index >= 0 else { return nil }
		guard index < subviews.count else { return nil }

		if let trackingItem = subviews[index] as? TrackingItem {
			return trackingItem.tracking?.date_end
		}

		return nil
	}

	func updateTrackingItem(withData data: Tracking) {
		if let item = subviews.first(where: {
			if let item = $0 as? TrackingItem {
				return item.tracking?.objectID == data.objectID
			}

			return false
		}) as? TrackingItem {
			item.tracking = data
		}
	}

	func removeTrackingsIfBetweenDateRange(in tracking: Tracking) {
		
	}

	func checkButtonsForRemovable() {
		for addButton in subviews.filter({ $0.isKind(of: AddButton.self) }) {
			let addButton = addButton as! AddButton

			if
				let index = subviews.firstIndex(of: addButton),
				let start = timeStartForItem(at: subviews.index(after: index)),
				let end = timeEndForItem(at: subviews.index(before: index)),
				[ComparisonResult.orderedDescending, ComparisonResult.orderedSame].contains(end.compare(start))
			{
				NSAnimationContext.runAnimationGroup({ context in
					context.duration = 0.25
					context.allowsImplicitAnimation = true

					addButton.constraint!.constant = 0
					layoutSubtreeIfNeeded()
				}, completionHandler: {
					self.removeView(addButton)
				})
			}
		}
	}

	func insertAddButtonsIfNeeded() {
		for trackingItem in subviews.filter({ $0.isKind(of: TrackingItem.self) }) {
			let trackingItem = trackingItem as! TrackingItem

			if
				let index = subviews.firstIndex(of: trackingItem),
				let start = trackingItem.tracking?.date_start,
				let end = timeEndForItem(at: subviews.index(before: index)),
				start.timeIntervalSince(end) > 60
			{
				insertAddButton(at: index)
			}
		}
	}

	func insertAddButton() {
		insertAddButton(at: nil)
	}

	func insertAddButton(at index: Int?) {
		let addButton = AddButton()

		if let index = index {
			insertView(addButton, at: index, in: .bottom)
		} else {
			addView(addButton, in: .bottom)
		}

		let buttonContraints = [
			NSLayoutConstraint(item: addButton, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0),
			NSLayoutConstraint(item: addButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 60)
		]
		addConstraints(buttonContraints)
	}

}
