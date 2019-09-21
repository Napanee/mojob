//
//  SettingsViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 04.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa
import ServiceManagement
import Crashlytics


class SettingsViewController: NSViewController {

	@IBOutlet weak var activitySelect: NSComboBox!
	@IBOutlet weak var autoLaunchCheckbox: NSButton!
	@IBOutlet weak var badgeIconLabel: NSButton!
	@IBOutlet weak var syncOnStartCheckbox: NSButton!
	@IBOutlet weak var noTrackingNotification: TextField!
	@IBOutlet weak var dayCompleteNotification: TextField!
	@IBOutlet weak var radioNormalWeek: NSButton!
	@IBOutlet weak var radioSpecialWeek: NSButton!
	@IBOutlet weak var specialWeekDetails: NSStackView!
	@IBOutlet weak var oddWeekHours: TextField!
	@IBOutlet weak var oddWeekDaysStackView: NSStackView!
	@IBOutlet weak var oddWeekMonday: NSButton!
	@IBOutlet weak var oddWeekTuesday: NSButton!
	@IBOutlet weak var oddWeekWednesday: NSButton!
	@IBOutlet weak var oddWeekThursday: NSButton!
	@IBOutlet weak var oddWeekFriday: NSButton!
	@IBOutlet weak var evenWeekHours: TextField!
	@IBOutlet weak var evenWeekDaysStackView: NSStackView!
	@IBOutlet weak var evenWeekMonday: NSButton!
	@IBOutlet weak var evenWeekTuesday: NSButton!
	@IBOutlet weak var evenWeekWednesday: NSButton!
	@IBOutlet weak var evenWeekThursday: NSButton!
	@IBOutlet weak var evenWeekFriday: NSButton!
	@IBOutlet weak var specialWeekDetailsTopConstraint: NSLayoutConstraint!

	var _specialWeekDetailsTopConstraint = NSLayoutConstraint()
	var radioButtonsWeek: [NSButton] = []
	var keyDownEventMonitor: Any?
	var userDefaults = UserDefaults()
	var oddWeekDays: [Int] = []
	var evenWeekDays: [Int] = []
	var activities: [Activity] = []
	let helperBundleName = "de.martinschneider.AutoLaunchHelper"

	override func viewDidLoad() {
		super.viewDidLoad()

		initActivitySelect()

		NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
			self.keyDown(with: $0)
			return $0
		}

		_specialWeekDetailsTopConstraint = specialWeekDetailsTopConstraint
		specialWeekDetailsTopConstraint.isActive = false
		radioButtonsWeek = [radioNormalWeek, radioSpecialWeek]

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

		if (userDefaults.object(forKey: UserDefaults.Keys.syncOnStart) == nil || userDefaults.bool(forKey: UserDefaults.Keys.syncOnStart)) {
			syncOnStartCheckbox.state = .on
		} else {
			syncOnStartCheckbox.state = .off
		}

		let noTrackingValue = userDefaults.integer(forKey: UserDefaults.Keys.notificationNotracking)
		noTrackingNotification.stringValue = userDefaults.contains(key: UserDefaults.Keys.notificationNotracking) ? String(noTrackingValue) : String(userDefaultValues.notificationNotracking)

		let dayCompleteValue = userDefaults.double(forKey: UserDefaults.Keys.notificationDaycomplete)
		dayCompleteNotification.stringValue = userDefaults.contains(key: UserDefaults.Keys.notificationDaycomplete) ? String(dayCompleteValue) : String(userDefaultValues.notificationDaycomplete)
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		let pstyle = NSMutableParagraphStyle()
		pstyle.firstLineHeadIndent = 5.0
		for button in radioButtonsWeek {
			button.attributedTitle = NSAttributedString(
				string: button.title,
				attributes: [
					NSAttributedString.Key.paragraphStyle: pstyle
				]
			)
		}

		oddWeekHours.stringValue = String(userDefaults.integer(forKey: UserDefaults.Keys.oddWeekHours))
		evenWeekHours.stringValue = String(userDefaults.integer(forKey: UserDefaults.Keys.evenWeekHours))

		let workWeek = userDefaults.string(forKey: UserDefaults.Keys.workWeek)
		if (workWeek == UserDefaults.workWeek.special) {
			radioSpecialWeek.state = .on
			toggleSpecialWeekDetails(show: true)
		} else {
			radioNormalWeek.state = .on
			toggleSpecialWeekDetails(show: false)
		}

		oddWeekDays = userDefaults.array(forKey: UserDefaults.Keys.oddWeekDays) as? [Int] ?? []
		oddWeekDaysStackView.subviews.filter({ $0.isKind(of: NSButton.self) }).forEach({
			($0 as! NSButton).state = oddWeekDays.contains($0.tag) ? .on : .off
		})

		evenWeekDays = userDefaults.array(forKey: UserDefaults.Keys.evenWeekDays) as? [Int] ?? []
		evenWeekDaysStackView.subviews.filter({ $0.isKind(of: NSButton.self) }).forEach({
			($0 as! NSButton).state = evenWeekDays.contains($0.tag) ? .on : .off
		})
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

	private func toggleSpecialWeekDetails(show: Bool) {
		specialWeekDetails.isHidden = !show
		specialWeekDetailsTopConstraint = _specialWeekDetailsTopConstraint
		specialWeekDetailsTopConstraint.isActive = show

		if (show) {
			let weekOddHours = Int(oddWeekHours.stringValue) ?? 30
			let weekEvenHours = Int(evenWeekHours.stringValue) ?? 30
			Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "WeekOdd:Hours:set", "Value": weekOddHours])
			Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "WeekEven:Hours:set", "Value": weekEvenHours])
			userDefaults.set(weekOddHours, forKey: UserDefaults.Keys.oddWeekHours)
			userDefaults.set(weekEvenHours, forKey: UserDefaults.Keys.evenWeekHours)
		} else {
			Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "WeekOdd:Hours:remove"])
			Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "WeekEven:Hours:remove"])
			userDefaults.removeObject(forKey: UserDefaults.Keys.oddWeekHours)
			userDefaults.removeObject(forKey: UserDefaults.Keys.evenWeekHours)
		}
	}

	@IBAction func activitySelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if (value == "") {
			Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "removeActivity"])
			userDefaults.removeObject(forKey: UserDefaults.Keys.activity)
		} else if let activity = CoreDataHelper.activities().first(where: { $0.title?.lowercased() == value }) {
			Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "setActivity", "Activity": activity.title ?? "no Title"])
			userDefaults.set(activity.id, forKey: UserDefaults.Keys.activity)
		}
	}

	@IBAction func toggleAutoLaunch(_ sender: NSButton) {
		let isAuto = sender.state == .on
		Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "autoLaunch", "Status": isAuto])
		SMLoginItemSetEnabled(helperBundleName as CFString, isAuto)
	}

	@IBAction func toggleBadgIconLabel(_ sender: NSButton) {
		let isActive = sender.state == .on
		Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "BadgeIconLabel", "Status": isActive])
		userDefaults.set(isActive, forKey: UserDefaults.Keys.badgeIconLabel)
	}

	@IBAction func toggleSyncOnStart(_ sender: NSButton) {
		let isActive = sender.state == .on
		Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "SyncOnStart", "Status": isActive])
		userDefaults.set(isActive, forKey: UserDefaults.Keys.syncOnStart)
	}

	@IBAction func resetData(_ sender: NSButton) {
		CoreDataHelper.resetData()
	}

	@IBAction func radioNormalWeek(_ sender: NSButton) {
		radioSpecialWeek.state = .off

		toggleSpecialWeekDetails(show: false)

		Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "Week", "Status": UserDefaults.workWeek.standard])
		userDefaults.set(UserDefaults.workWeek.standard, forKey: UserDefaults.Keys.workWeek)
	}

	@IBAction func radioSpecialWeek(_ sender: NSButton) {
		radioNormalWeek.state = .off

		toggleSpecialWeekDetails(show: true)

		Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "Week", "Status": UserDefaults.workWeek.special])
		userDefaults.set(UserDefaults.workWeek.special, forKey: UserDefaults.Keys.workWeek)
	}

	@IBAction func oddWeekDay(_ sender: NSButton) {
		if (sender.state == .on) {
			oddWeekDays.append(sender.tag)
		} else {
			oddWeekDays = oddWeekDays.filter({ $0 != sender.tag })
		}

		userDefaults.set(oddWeekDays, forKey: UserDefaults.Keys.oddWeekDays)
	}

	@IBAction func evenWeekDay(_ sender: NSButton) {
		if (sender.state == .on) {
			evenWeekDays.append(sender.tag)
		} else {
			evenWeekDays = evenWeekDays.filter({ $0 != sender.tag })
		}

		userDefaults.set(evenWeekDays, forKey: UserDefaults.Keys.evenWeekDays)
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

		if (textField == oddWeekHours) {
			let weekOddHours = Int(oddWeekHours.stringValue) ?? 30
			Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "WeekOdd:Hours:set", "Value": weekOddHours])
			userDefaults.set(weekOddHours, forKey: UserDefaults.Keys.oddWeekHours)
		}

		if (textField == evenWeekHours) {
			let weekEvenHours = Int(evenWeekHours.stringValue) ?? 30
			Answers.logCustomEvent(withName: "Settings", customAttributes: ["Action": "WeekEven:Hours:set", "Value": weekEvenHours])
			userDefaults.set(weekEvenHours, forKey: UserDefaults.Keys.evenWeekHours)
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
