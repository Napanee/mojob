//
//  SettingsViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 04.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class SettingsViewController: NSViewController {

	@IBOutlet weak var activitySelect: NSPopUpButton!

	var userDefaults = UserDefaults()

	override func viewDidLoad() {
		super.viewDidLoad()

		initActivitySelect()
	}

	private func initActivitySelect() {
		activitySelect.removeAllItems()

		if let activities = QuoJob.shared.activities {
			let activityTitles = activities.sorted(by: { $0.title! < $1.title! }).map({ $0.title })
			activitySelect.addItem(withTitle: "Leistungsart wählen")
			activitySelect.addItems(withTitles: activityTitles as! [String])

			if let defaultJobId = userDefaults.string(forKey: "activity"), let activity = activities.first(where: { $0.id == defaultJobId }), let title = activity.title {
				if let index = activityTitles.firstIndex(of: title) {
					activitySelect.selectItem(at: index + 1)
				}
			}
		}
	}

	@IBAction func activitySelect(_ sender: NSPopUpButton) {
		let title = sender.titleOfSelectedItem
		guard let activity = QuoJob.shared.activities?.first(where: { $0.title == title }) else {
			userDefaults.removeObject(forKey: "activity")

			return
		}

		userDefaults.set(activity.id, forKey: "activity")
	}

}
