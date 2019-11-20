//
//  FavoriteItem.swift
//  MoJob
//
//  Created by Martin Schneider on 09.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class FavoriteItem: NSCollectionViewItem {

	var favorite: Favorite! {
		didSet {
			headlineLabel?.stringValue = "\(favorite.job?.fullTitle ?? "Kein Job")"

			var sublineTexts: [String] = []

			if let activityTitle = favorite.activity?.title {
				sublineTexts.append(activityTitle)
			}

			if let taskTitle = favorite.task?.title {
				sublineTexts.append(taskTitle)
			}

			if (sublineTexts.count > 0) {
				sublineLabel?.stringValue = "\(sublineTexts.joined(separator: ", "))"
			} else {
				sublineLabel.removeFromSuperview()
			}

			headlineView.color = nil
			if
				let path = Bundle.main.path(forResource: "MoJob", ofType: "clr"),
				let colors = NSColorList(name: "MoJob", fromFile: path),
				let jobColor = favorite.job?.color,
				let color = colors.color(withKey: jobColor)
			{
				headlineView.color = color
			}
		}
	}
	var trackingArea: NSTrackingArea?
	let indicatorLayer = CALayer()

	@IBOutlet weak var headlineView: FavoriteHeadlineView!
	@IBOutlet weak var headlineLabel: NSTextField!
	@IBOutlet weak var sublineLabel: NSTextField!
	@IBOutlet weak var deleteButton: NSButton!
	@IBOutlet weak var startButton: NSButton!

	override func viewDidLayout() {
		trackingArea = NSTrackingArea(
			rect: view.bounds,
			options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited],
			owner: self,
			userInfo: nil
		)

		view.addTrackingArea(trackingArea!)
	}

	override func viewDidDisappear() {
		if let trackingArea = trackingArea {
			DispatchQueue.main.async {
				self.view.removeTrackingArea(trackingArea)
			}
		}
	}

	@IBAction func deleteButton(_ sender: NSButton) {
		CoreDataHelper.deleteFavorite(favorite: favorite)
	}

	@IBAction func startButton(_ sender: NSButton) {
		startTracking()
	}

	override func mouseEntered(with event: NSEvent) {
		super.mouseEntered(with: event)

		if #available(OSX 10.14, *) {
			view.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
		} else {
			view.layer?.backgroundColor = NSColor.controlHighlightColor.cgColor
		}
	}

	override func mouseExited(with event: NSEvent) {
		super.mouseExited(with: event)

		view.layer?.backgroundColor = nil
	}

	override func mouseUp(with event: NSEvent) {
		super.mouseUp(with: event)

		startTracking()
	}

	private func startTracking() {
		guard let tracking = CoreDataHelper.createTracking(in: CoreDataHelper.currentTrackingContext) else { return }

		tracking.job = CoreDataHelper
			.jobs(in: CoreDataHelper.currentTrackingContext)
			.first(where: { $0.id == favorite.job?.id })

		if let activity = CoreDataHelper.activities(in: CoreDataHelper.currentTrackingContext).first(where: { $0.id == favorite.activity?.id }) {
			tracking.activity = activity
		}

		if let task = CoreDataHelper.tasks(in: CoreDataHelper.currentTrackingContext).first(where: { $0.id == favorite.task?.id }) {
			tracking.task = task
		}

		(NSApp.mainWindow?.windowController as? MainWindowController)?.mainSplitViewController?.showTracking()
	}

}
