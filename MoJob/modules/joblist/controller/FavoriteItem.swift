//
//  FavoriteItem.swift
//  MoJob
//
//  Created by Martin Schneider on 09.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class FavoriteItem: NSCollectionViewItem {

	var job: Job!
	var delegate: FavoritesItemDelegate!
	let indicatorLayer = CALayer()

	@IBOutlet weak var deleteButton: NSButton!
	@IBOutlet weak var startButton: NSButton!

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

	@IBAction func deleteButton(_ sender: NSButton) {
		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext

		job.isFavorite = false

		do {
			try context.save()
			delegate.onDeleteFavorite()
		} catch let error {
			print(error)
		}
	}

	@IBAction func startButton(_ sender: NSButton) {
		if let appDelegate = NSApp.delegate as? AppDelegate, let mainWindowController = appDelegate.mainWindowController, let contentViewController = mainWindowController.currentContentViewController as? TrackingSplitViewController {
			appDelegate.currentTracking(job: job)
			contentViewController.showTracking()
		}
	}

}
