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
	var isHighlighted: Bool! = false {
		didSet {
			updateBackground(value: isHighlighted)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
	}

	func updateBackground(value: Bool) {
		if let view = view as? CollectionItemView {
			view.highlightBackground(is: value)
		}
	}

}