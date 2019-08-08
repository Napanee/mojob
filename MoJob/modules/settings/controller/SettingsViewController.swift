//
//  SettingsViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 04.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa
import ServiceManagement

class SettingsViewController: NSViewController {

	@IBOutlet weak var activitySelect: NSComboBox!
	@IBOutlet weak var autoLaunchCheckbox: NSButton!
	@IBOutlet weak var noTrackingNotification: TextField!
	@IBOutlet weak var dayCompleteNotification: TextField!

	var userDefaults = UserDefaults()
	var activities: [Activity] = []
	let helperBundleName = "de.martinschneider.AutoLaunchHelper"

	override func viewDidLoad() {
		super.viewDidLoad()

		initActivitySelect()

		let foundHelper = NSWorkspace.shared.runningApplications.contains {
			$0.bundleIdentifier == helperBundleName
		}

		let pstyle = NSMutableParagraphStyle()
		pstyle.firstLineHeadIndent = 5.0
		autoLaunchCheckbox.attributedTitle = NSAttributedString(
			string: autoLaunchCheckbox.title,
			attributes: [
				NSAttributedString.Key.paragraphStyle: pstyle
			]
		)

		autoLaunchCheckbox.state = foundHelper ? .on : .off

		let noTrackingValue = userDefaults.integer(forKey: UserDefaults.Keys.notificationNotracking)
		noTrackingNotification.stringValue = userDefaults.contains(key: UserDefaults.Keys.notificationNotracking) ? String(noTrackingValue) : String(userDefaultValues.notificationNotracking)

		let dayCompleteValue = userDefaults.double(forKey: UserDefaults.Keys.notificationDaycomplete)
		dayCompleteNotification.stringValue = userDefaults.contains(key: UserDefaults.Keys.notificationDaycomplete) ? String(dayCompleteValue) : String(userDefaultValues.notificationDaycomplete)
	}

	private func initActivitySelect() {
		activitySelect.placeholderString = "Leistungsart wählen oder eingeben"

		if let activities = QuoJob.shared.activities {
			self.activities = activities.sorted(by: { $0.title! < $1.title! })
		}

		activitySelect.reloadData()

		if let activityId = userDefaults.string(forKey: UserDefaults.Keys.activity) {
			if let index = activities.index(where: { $0.id == activityId }) {
				activitySelect.selectItem(at: index)
			}
		}
	}

	@IBAction func activitySelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			userDefaults.removeObject(forKey: UserDefaults.Keys.activity)
		} else if let activities = QuoJob.shared.activities, let activity = activities.first(where: { $0.title?.lowercased() == value }) {
			userDefaults.set(activity.id, forKey: UserDefaults.Keys.activity)
		}
	}

	@IBAction func toggleAutoLaunch(_ sender: NSButton) {
		let isAuto = sender.state == .on
		SMLoginItemSetEnabled(helperBundleName as CFString, isAuto)
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
		if let textField = obj.object as? NSTextField {
			handleTextChange(in: textField)
		}

		if let comboBox = obj.object as? NSComboBox {
			handleTextChange(in: comboBox)
		}
	}

	private func handleTextChange(in textField: NSTextField) {
		if (textField == noTrackingNotification) {
			guard let value = Int(textField.stringValue) else { return }

			if (value > 0) {
				userDefaults.set(value, forKey: UserDefaults.Keys.notificationNotracking)
			} else {
				userDefaults.removeObject(forKey: UserDefaults.Keys.notificationNotracking)
			}
		}

		if (textField == dayCompleteNotification) {
			guard let value = Double(textField.stringValue.replacingOccurrences(of: ",", with: ".")) else { return }

			if (value > 0) {
				userDefaults.set(value, forKey: UserDefaults.Keys.notificationDaycomplete)
			} else {
				userDefaults.removeObject(forKey: UserDefaults.Keys.notificationDaycomplete)
			}
		}
	}

	private func handleTextChange(in comboBox: NSComboBox) {
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
