//
//  FavoriteItem.swift
//  MoJob
//
//  Created by Martin Schneider on 09.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class FavoriteItem: NSCollectionViewItem {

	@IBOutlet weak var deleteButton: NSButton!
	@IBOutlet weak var startButton: NSButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		view.wantsLayer = true
	}

	@IBAction func deleteButton(_ sender: NSButton) {
	}

	@IBAction func startButton(_ sender: NSButton) {
		let window = (NSApp.delegate as! AppDelegate).window

		if let contentViewController = window?.contentViewController as? SplitViewController {
			contentViewController.showTracking()
		}
	}

}
