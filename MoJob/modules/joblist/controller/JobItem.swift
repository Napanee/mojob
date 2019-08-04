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
	}

	func updateBackground(value: Bool) {
		if let view = view as? CollectionItemView {
			view.highlightBackground(is: value)
		}
	}

	@IBAction func startButton(_ sender: NSButton) {
		if let appDelegate = NSApp.delegate as? AppDelegate, let mainWindowController = appDelegate.mainWindowController, let contentViewController = mainWindowController.currentContentViewController as? TrackingSplitViewController {
			appDelegate.currentTracking(job: job)
			contentViewController.showTracking()
		}
	}

}
