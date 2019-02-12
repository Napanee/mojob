//
//  FavoriteItem.swift
//  MoJob
//
//  Created by Martin Schneider on 09.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class FavoriteItem: NSCollectionViewItem {

	override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

		view.wantsLayer = true
    }

	@IBAction func startTracking(_ sender: NSButton) {
		let vc = TrackingViewController(nibName: nibNames.TrackingViewController, bundle: nil)
		let animator = CustomAnimator()
		let window = (NSApp.delegate as! AppDelegate).window

		if let contentViewController = window?.contentViewController as? SplitViewController {
			contentViewController.showTracking()
		}
	}
    
}
