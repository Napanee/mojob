//
//  AddFavorite.swift
//  MoJob
//
//  Created by Martin Schneider on 02.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


class AddFavorite: NSViewController {

	@IBOutlet weak var jobSelect: NSPopUpButton!
	@IBOutlet weak var saveButton: NSButton!

	var delegate: AddFavoriteDelegate!

	override func viewDidLoad() {
		super.viewDidLoad()

		jobSelect.removeAllItems()

		let jobTitles = QuoJob.shared.jobs
			.filter({ $0.number != nil && $0.title != nil })
			.sorted(by: { $0.number! != $1.number! ? $0.number! < $1.number! : $0.title! < $1.title! })
			.map({ "\($0.number!) - \($0.title!)" })

		if (jobTitles.count > 0) {
			jobSelect.addItem(withTitle: "Job wählen")
			jobSelect.addItems(withTitles: jobTitles)
		}
	}

	@IBAction func jobSelect(_ sender: NSPopUpButton) {
		let title = sender.titleOfSelectedItem

		guard let _ = QuoJob.shared.jobs.first(where: { "\($0.number!) - \($0.title!)" == title }) else {
			saveButton.isEnabled = false
			return
		}

		saveButton.isEnabled = true
	}

	@IBAction func save(_ sender: NSButton) {
		let title = jobSelect.titleOfSelectedItem

		if let job = QuoJob.shared.jobs.first(where: { "\($0.number!) - \($0.title!)" == title }) {
			job.update(with: ["isFavorite": true]).done({ _ in }).catch({ _ in })

			delegate.onDismiss()

			dismiss(self)
		}
	}

}
