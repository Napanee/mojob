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
	@IBOutlet weak var badgeIconLabel: NSButton!
	@IBOutlet weak var noTrackingNotification: TextField!
	@IBOutlet weak var dayCompleteNotification: TextField!
	@IBOutlet weak var extendSettings: NSView!

	var keyDownEventMonitor: Any?
	var userDefaults = UserDefaults()
	var activities: [Activity] = []
	let helperBundleName = "de.martinschneider.AutoLaunchHelper"

	override func viewDidLoad() {
		super.viewDidLoad()

		initActivitySelect()

		NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
			self.keyDown(with: $0)
			return $0
		}

		extendSettings.wantsLayer = true
		extendSettings.layer?.borderColor = NSColor.red.cgColor
		extendSettings.layer?.borderWidth = 2.0
		extendSettings.layer?.backgroundColor = NSColor.red.withAlphaComponent(0.5).cgColor

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

		if (userDefaults.object(forKey: UserDefaults.Keys.badgeIconLabel) == nil || userDefaults.bool(forKey: UserDefaults.Keys.badgeIconLabel)) {
			badgeIconLabel.state = .on
		} else {
			badgeIconLabel.state = .off
		}

		let noTrackingValue = userDefaults.integer(forKey: UserDefaults.Keys.notificationNotracking)
		noTrackingNotification.stringValue = userDefaults.contains(key: UserDefaults.Keys.notificationNotracking) ? String(noTrackingValue) : String(userDefaultValues.notificationNotracking)

		let dayCompleteValue = userDefaults.double(forKey: UserDefaults.Keys.notificationDaycomplete)
		dayCompleteNotification.stringValue = userDefaults.contains(key: UserDefaults.Keys.notificationDaycomplete) ? String(dayCompleteValue) : String(userDefaultValues.notificationDaycomplete)
	}

	private func initActivitySelect() {
		activitySelect.placeholderString = "Leistungsart wählen oder eingeben"

		activities = CoreDataHelper.activities()
			.filter({ $0.title != nil })
			.sorted(by: { $0.title! < $1.title! })

		activitySelect.reloadData()

		if let activityId = userDefaults.string(forKey: UserDefaults.Keys.activity) {
			if let index = activities.firstIndex(where: { $0.id == activityId }) {
				activitySelect.selectItem(at: index)
			}
		}
	}

	override func keyDown(with event: NSEvent) {
		switch event.modifierFlags.intersection(.deviceIndependentFlagsMask) {
		case [.command] where event.characters == "d":
			extendSettings.isHidden = false
		default:
			break
		}
	}

	@IBAction func activitySelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			userDefaults.removeObject(forKey: UserDefaults.Keys.activity)
		} else if let activity = CoreDataHelper.activities().first(where: { $0.title?.lowercased() == value }) {
			userDefaults.set(activity.id, forKey: UserDefaults.Keys.activity)
		}
	}

	@IBAction func toggleAutoLaunch(_ sender: NSButton) {
		let isAuto = sender.state == .on
		SMLoginItemSetEnabled(helperBundleName as CFString, isAuto)
	}

	@IBAction func toggleBadgIconLabel(_ sender: NSButton) {
		userDefaults.set(sender.state == .on, forKey: UserDefaults.Keys.badgeIconLabel)
	}

	@IBAction func resetData(_ sender: NSButton) {
		CoreDataHelper.resetData()
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

			activities = CoreDataHelper.activities()
				.filter({ $0.title!.lowercased().contains(selectedValue.lowercased()) })
				.sorted(by: { $0.title! < $1.title! })

			comboBox.reloadData()

			if (activities.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			}
		}
	}
}
