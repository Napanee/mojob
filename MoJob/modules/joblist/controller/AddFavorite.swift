//
//  AddFavorite.swift
//  MoJob
//
//  Created by Martin Schneider on 02.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


class AddFavorite: QuoJobSelections {

	override var formIsValid: Bool {
		get {
			let job = CoreDataHelper.jobs().first(where: { $0.fullTitle.lowercased() == jobSelect.stringValue.lowercased() })
			let task = CoreDataHelper.tasks().first(where: { $0.title?.lowercased() == taskSelect.stringValue.lowercased() })
			let activity = CoreDataHelper.activities().first(where: { $0.title?.lowercased() == activitySelect.stringValue.lowercased() })
			let isFavorite = CoreDataHelper.favorite(job: job, task: task, activity: activity) != nil

			if (job == nil) {
				errorLabel.stringValue = "Du musst mindestens einen Job auswählen."
				errorLabel.isHidden = false
			} else if (isFavorite) {
				errorLabel.stringValue = "Es gibt schon einen Favoriten mit deiner Auswahl."
				errorLabel.isHidden = false
			} else {
				errorLabel.isHidden = true
			}

			return errorLabel.isHidden
		}
		set {
			saveButton.isEnabled = newValue && formIsValid
		}
	}

	@IBOutlet weak var errorLabel: NSTextField!
	@IBOutlet weak var saveButton: NSButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		initEditor()
	}

	@IBAction func save(_ sender: NSButton) {
		let job = CoreDataHelper.jobs().first(where: { $0.fullTitle.lowercased() == jobSelect.stringValue.lowercased() })
		let activity = CoreDataHelper.activities().first(where: { $0.title?.lowercased() == activitySelect.stringValue.lowercased() })
		let task = CoreDataHelper.tasks().first(where: { $0.title?.lowercased() == taskSelect.stringValue.lowercased() })

		CoreDataHelper.createFavorite(job: job, task: task, activity: activity)

		dismiss(self)
	}

}
