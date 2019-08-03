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

		if let jobs = QuoJob.shared.jobs {
			let jobTitles = jobs
				.sorted(by: {
					$0.type!.id! != $1.type!.id! && $0.type!.title! < $1.type!.title! ||
						$0.number! != $1.number! && $0.number! < $1.number! ||
						$0.title! < $1.title!
				})
				.map({ job -> String in
					guard let title = job.title, let number = job.number else { return "" }

					return "\(number) - \(title)"
				})

			jobSelect.addItem(withTitle: "Job wählen")
			jobSelect.addItems(withTitles: jobTitles)
		}
	}

}
