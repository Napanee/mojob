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

		if let jobs = QuoJob.shared.jobs {
			let jobTitles = jobs
				.filter({!$0.isFavorite})
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

	@IBAction func jobSelect(_ sender: NSPopUpButton) {
		let title = sender.titleOfSelectedItem

		guard let _ = QuoJob.shared.jobs?.first(where: { "\($0.number!) - \($0.title!)" == title }) else {
			saveButton.isEnabled = false
			return
		}

		saveButton.isEnabled = true
	}

	@IBAction func save(_ sender: NSButton) {
		let title = jobSelect.titleOfSelectedItem

		if let job = QuoJob.shared.jobs?.first(where: { "\($0.number!) - \($0.title!)" == title }) {
			let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
			job.isFavorite = true
			try! context.save()

			delegate.onDismiss()

			dismiss(self)
		}
	}

	@IBAction func cancel(_ sender: NSButton) {
		dismiss(self)
	}

}
