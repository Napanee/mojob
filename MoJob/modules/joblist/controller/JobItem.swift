//
//  JobItem.swift
//  MoJob
//
//  Created by Martin Schneider on 09.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class JobItem: NSCollectionViewItem {

	let backgroundLayer = CALayer()
	var job: Job!
	var trackingArea: NSTrackingArea?
	var delegate: JobItemDelegate!
	let indicatorLayer = CALayer()
	var isHighlighted: Bool! = false {
		didSet {
			updateBackground(value: isHighlighted)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
	}

	override func viewDidLayout() {
		view.wantsLayer = true
		view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
		view.layer?.sublayers?.removeAll(where: { $0.isEqual(to: indicatorLayer) })

		if let path = Bundle.main.path(forResource: "MoJob", ofType: "clr"),
			let colors = NSColorList(name: "MoJob", fromFile: path), let jobColor = job.color,
			let color = colors.color(withKey: jobColor) {

			indicatorLayer.frame = CGRect(x: 15, y: view.frame.height / 2 - 6, width: 12, height: 12)
			indicatorLayer.cornerRadius = 6
			indicatorLayer.borderColor = NSColor.darkGray.cgColor
			indicatorLayer.borderWidth = 1
			indicatorLayer.backgroundColor = color.cgColor

			view.layer?.addSublayer(indicatorLayer)
		}

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
			view.removeTrackingArea(trackingArea)
		}
	}

	func updateBackground(value: Bool) {
		if let view = view as? CollectionItemView {
			view.highlightBackground(is: value)
		}
	}

	@IBAction func startButton(_ sender: NSButton) {
		startTracking()
	}

	override func mouseEntered(with event: NSEvent) {
		super.mouseEntered(with: event)

		if #available(OSX 10.14, *) {
			view.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.2).cgColor
		} else {
			view.layer?.backgroundColor = CGColor(red: 0.000, green: 0.478, blue: 1.000, alpha: 0.2)
		}
	}

	override func mouseExited(with event: NSEvent) {
		super.mouseExited(with: event)

		view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
	}

	override func mouseDown(with event: NSEvent) {
		super.mouseDown(with: event)

		startTracking()
	}

	private func startTracking() {
		guard let tracking = CoreDataHelper.createTracking(in: CoreDataHelper.currentTrackingContext) else { return }

		let jobTrackingContext = CoreDataHelper.jobs(in: CoreDataHelper.currentTrackingContext)
		tracking.job = jobTrackingContext.first(where: { $0.id == job.id })

		(NSApp.mainWindow?.windowController as? MainWindowController)?.mainSplitViewController?.showTracking()

		delegate.onSelectJob()
	}

}
