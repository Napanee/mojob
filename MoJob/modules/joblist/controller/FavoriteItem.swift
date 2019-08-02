//
//  FavoriteItem.swift
//  MoJob
//
//  Created by Martin Schneider on 09.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class FavoriteItem: NSCollectionViewItem {

	var job: Job! = nil
	var delegate: FavoritesItemDelegate!

	@IBOutlet weak var deleteButton: NSButton!
	@IBOutlet weak var startButton: NSButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		view.wantsLayer = true
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
		if let appDelegate = NSApp.delegate as? AppDelegate, let window = appDelegate.window, let contentViewController = window.contentViewController as? SplitViewController {
			appDelegate.currentTracking(job: job)
			contentViewController.showTracking()
		}
	}

}
