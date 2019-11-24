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
			let indexJob = jobSelect.indexOfSelectedItem
			let indexTask = taskSelect.indexOfSelectedItem
			let indexActivity = activitySelect.indexOfSelectedItem

			if (indexJob < 0) {
				errorLabel.stringValue = "Du musst mindestens einen Job auswählen."
				errorLabel.isHidden = false

				return false
			}

			if (indexJob >= 0 && jobs.count > indexJob && indexTask >= 0 && tasks.count > indexTask && indexActivity >= 0 && activities.count > indexActivity && CoreDataHelper.favorite(job: jobs[indexJob], task: tasks[indexTask], activity: activities[indexActivity]) != nil) {
				errorLabel.stringValue = "Es gibt schon einen Favoriten mit deiner Auswahl."
				errorLabel.isHidden = false

				return false
			}

			errorLabel.isHidden = true

			return true
		}
		set {
			saveButton.isEnabled = newValue && formIsValid
		}
	}

	@IBOutlet weak var errorLabel: NSTextField!
	@IBOutlet weak var saveButton: NSButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		nfc = false

		initEditor()
	}

	@IBAction func save(_ sender: NSButton) {
		let indexJob = jobSelect.indexOfSelectedItem
		let indexTask = taskSelect.indexOfSelectedItem
		let indexActivity = activitySelect.indexOfSelectedItem

		var job: Job?
		var task: Task?
		var activity: Activity?

		if (indexJob >= 0 && jobs.count > indexJob) {
			job = jobs[indexJob]
		}

		if (indexTask >= 0 && tasks.count > indexTask) {
			task = tasks[indexTask]
		}

		if (indexActivity >= 0 && activities.count > indexActivity) {
			activity = activities[indexActivity]
		}

		CoreDataHelper.createFavorite(job: job, task: task, activity: activity)

		dismiss(self)
	}

}
