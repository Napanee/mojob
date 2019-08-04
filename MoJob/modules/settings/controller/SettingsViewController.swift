//
//  SettingsViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 04.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class SettingsViewController: NSViewController {

	@IBOutlet weak var activitySelect: NSComboBox!

	var userDefaults = UserDefaults()
	var activities: [Activity] = []

	override func viewDidLoad() {
		super.viewDidLoad()

		initActivitySelect()
	}

	private func initActivitySelect() {
		activitySelect.placeholderString = "Leistungsart wählen oder eingeben"

		if let activities = QuoJob.shared.activities {
			self.activities = activities.sorted(by: { $0.title! < $1.title! })
		}

		activitySelect.reloadData()

		if let activityId = userDefaults.string(forKey: "activity") {
			if let index = activities.index(where: { $0.id == activityId }) {
				activitySelect.selectItem(at: index)
			}
		}
	}

	@IBAction func activitySelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			userDefaults.removeObject(forKey: "activity")
		} else if let activities = QuoJob.shared.activities, let activity = activities.first(where: { $0.title?.lowercased() == value }) {
			userDefaults.set(activity.id, forKey: "activity")
		}
	}

}

extension SettingsViewController: NSComboBoxDataSource {
	func numberOfItems(in comboBox: NSComboBox) -> Int {
		return activities.count
	}

	func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
		return activities[index].title
	}
}

extension SettingsViewController: NSTextFieldDelegate {
	func controlTextDidChange(_ obj: Notification) {
		let comboBox = obj.object as! NSComboBox

		if let comboBoxCell = comboBox.cell as? NSComboBoxCell {
			let selectedValue = comboBoxCell.stringValue

			activities = QuoJob.shared.activities!
				.filter({ $0.title!.lowercased().contains(selectedValue.lowercased()) })
				.sorted(by: { $0.title! < $1.title! })

			if (activities.count > 0) {
				comboBox.reloadData()
				comboBoxCell.perform(Selector(("popUp:")))
			}
		}
	}
}
