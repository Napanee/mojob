//
//  SplitJobItem.swift
//  MoJob
//
//  Created by Martin Schneider on 02.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class SplitJobItem: NSCollectionViewItem {

	@IBOutlet weak var jobSelect: NSPopUpButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		jobSelect.removeAllItems()

		let jobTitles = CoreDataHelper.jobs()
			.filter({ $0.number != nil && $0.title != nil })
			.sorted(by: { $0.number! != $1.number! ? $0.number! < $1.number! : $0.title! < $1.title! })
			.map({ "\($0.number!) - \($0.title!)" })

		if (jobTitles.count > 0) {
			jobSelect.addItem(withTitle: "Job wählen")
			jobSelect.addItems(withTitles: jobTitles)
		}
	}

}
