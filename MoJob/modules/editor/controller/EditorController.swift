//
//  EditorController.swift
//  MoJob
//
//  Created by Martin Schneider on 08.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

protocol DateFieldDelegate {
	func getFromMonth() -> Int?
	func getFromYear() -> Int?
	func getUntilMonth() -> Int?
	func getUntilYear() -> Int?
}

class EditorController: NSViewController, DateFieldDelegate, NSTextFieldDelegate {
	var tracking: Tracking? {
		didSet {
			if let tracking = tracking {
				self.tempTracking = TempTracking(tracking: tracking)
			}
		}
	}
	var tempTracking: TempTracking!
	var formIsValid: Bool {
		get {
			if ((tempTracking.date_end ?? Date()).timeIntervalSince(tempTracking.date_start) > 60 && (tempTracking.job != nil || tempTracking.customJob != nil) && tempTracking.activity != nil) {
				return true
			}

			return false
		}
	}

	let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext

	@IBOutlet weak var fromDay: NumberField!
	@IBOutlet weak var fromMonth: NumberField!
	@IBOutlet weak var fromYear: NumberField!
	@IBOutlet weak var fromHour: NumberField!
	@IBOutlet weak var fromMinute: NumberField!
	@IBOutlet weak var untilHour: NumberField!
	@IBOutlet weak var untilMinute: NumberField!
	@IBOutlet weak var untilDay: NumberField!
	@IBOutlet weak var untilMonth: NumberField!
	@IBOutlet weak var untilYear: NumberField!
	@IBOutlet weak var comment: NSTextField!
	@IBOutlet weak var colorPicker: NSPopUpButton!
	@IBOutlet weak var jobSelect: NSPopUpButton!
	@IBOutlet weak var taskSelect: NSPopUpButton!
	@IBOutlet weak var activitySelect: NSPopUpButton!
	@IBOutlet weak var saveButton: NSButton!
	@IBOutlet weak var deleteButton: NSButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		initColorPicker()

		fromDay.dateDelegate = self
		untilDay.dateDelegate = self

		jobSelect.removeAllItems()
		taskSelect.removeAllItems()
		activitySelect.removeAllItems()

		saveButton.isEnabled = formIsValid
		deleteButton.isHidden = tracking == nil

		if let jobs = QuoJob.shared.jobs, let tracking = tempTracking {
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
			let type = tracking.job?.type
			jobSelect.addItem(withTitle: "Job wählen")
			jobSelect.addItems(withTitles: jobTitles)

			if let job = tracking.job, let title = job.title, let number = job.number {
				let fullJobTitle = "\(number) - \(title)"
				if let index = jobTitles.firstIndex(of: fullJobTitle) {
					jobSelect.selectItem(at: index + 1)
				}
			}

			if let tasks = QuoJob.shared.tasks {
				let taskTitles = tasks.filter({ $0.job!.id == tracking.job?.id }).sorted(by: { $0.title! < $1.title! }).map({ $0.title })

				if (taskTitles.count > 0) {
					taskSelect.addItem(withTitle: "Aufgabe wählen")
					taskSelect.addItems(withTitles: taskTitles as! [String])

					if let index = taskTitles.firstIndex(of: tracking.task?.title) {
						taskSelect.selectItem(at: index + 1)
					}
				} else {
					taskSelect.isEnabled = false
				}
			}

			if let activities = QuoJob.shared.activities {
				let activityTitles = activities.filter({
					(type?.internal_service ?? true && $0.internal_service) ||
					(type?.productive_service ?? true && $0.external_service)
				}).sorted(by: { $0.title! < $1.title! }).map({ $0.title })
				activitySelect.addItem(withTitle: "Leistungsart wählen")
				activitySelect.addItems(withTitles: activityTitles as! [String])

				if let index = activityTitles.firstIndex(of: tracking.activity?.title) {
					activitySelect.selectItem(at: index + 1)
				}
			}
		}

		if let commentString = tempTracking.comment {
			comment.stringValue = commentString
		}

		let dateStart = tempTracking.date_start
		let day = Calendar.current.component(.day, from: dateStart)
		fromDay.stringValue = String(format: "%02d", day)
		let month = Calendar.current.component(.month, from: dateStart)
		fromMonth.stringValue = String(format: "%02d", month)
		let year = Calendar.current.component(.year, from: dateStart)
		fromYear.stringValue = String(year)

		let hour = Calendar.current.component(.hour, from: dateStart)
		fromHour.stringValue = String(format: "%02d", hour)
		let minute = Calendar.current.component(.minute, from: dateStart)
		fromMinute.stringValue = String(format: "%02d", minute)

		if let dateEnd = tempTracking.date_end {
			let day = Calendar.current.component(.day, from: dateEnd)
			untilDay.stringValue = String(format: "%02d", day)
			let month = Calendar.current.component(.month, from: dateEnd)
			untilMonth.stringValue = String(format: "%02d", month)
			let year = Calendar.current.component(.year, from: dateEnd)
			untilYear.stringValue = String(year)

			let hour = Calendar.current.component(.hour, from: dateEnd)
			untilHour.stringValue = String(format: "%02d", hour)
			let minute = Calendar.current.component(.minute, from: dateEnd)
			untilMinute.stringValue = String(format: "%02d", minute)
		}
	}

	func getFromMonth() -> Int? {
		return Int(fromMonth.stringValue)
	}

	func getFromYear() -> Int? {
		return Int(fromYear.stringValue)
	}

	func getUntilMonth() -> Int? {
		return Int(untilMonth.stringValue)
	}

	func getUntilYear() -> Int? {
		return Int(untilYear.stringValue)
	}

	func controlTextDidChange(_ obj: Notification) {
		guard let textField = obj.object as? NSTextField else { return }

		let formatter = DateFormatter()
		formatter.dateFormat = "YYYY/MM/dd HH:mm"

		if ([fromMinute, fromHour, fromDay, fromMonth, fromYear].contains(textField)) {
			if let newDate = formatter.date(from: "\(fromYear.stringValue)/\(fromMonth.stringValue)/\(fromDay.stringValue) \(fromHour.stringValue):\(fromMinute.stringValue)"),
				tempTracking.date_start.compare(newDate) != .orderedSame
			{
				tempTracking.date_start = newDate
			}
		}

		if ([untilMinute, untilHour, untilDay, untilMonth, untilYear].contains(textField)) {
			if let oldDate = tempTracking.date_end,
				let newDate = formatter.date(from: "\(untilYear.stringValue)/\(untilMonth.stringValue)/\(untilDay.stringValue) \(untilHour.stringValue):\(untilMinute.stringValue)"),
				oldDate.compare(newDate) != .orderedSame
			{
				tempTracking.date_end = newDate
			}
		}

		saveButton.isEnabled = formIsValid
	}

//	private func validateData() -> Bool {
//		guard let dateEnd = tracking.date_end, let dateStart = tracking.date_start else {
//			return false
//		}
//
//		if (dateStart.compare(dateEnd) == .orderedDescending) {
//			return false
//		}
//
//		return true
//	}

	private func initColorPicker() {
		colorPicker.isHidden = true
		return

		// @TODO ColorPicker
		let menu = NSMenu()
		let size = NSSize(width: 50, height: 19)

		if let crayons = NSColorList.init(named: "Crayons") {
			for key in crayons.allKeys.filter({
				if
					let color = crayons.color(withKey: $0),
					let red = color.usingColorSpace(.deviceRGB)?.redComponent,
					let green = color.usingColorSpace(.deviceRGB)?.greenComponent,
					let blue = color.usingColorSpace(.deviceRGB)?.blueComponent
				{
					return round(red * 100) != round(green * 100) || round(red * 100) != round(blue * 100)
				}

				return false
			}) {
				let item = NSMenuItem(title: key, action: nil, keyEquivalent: "")
				item.image = swatch(size: size, color: crayons.color(withKey: key) ?? .red)
				menu.addItem(item)
			}
		}

		colorPicker.menu = menu
		colorPicker.imagePosition = .imageOnly
		colorPicker.wantsLayer = true
		colorPicker.selectItem(at: 5)

		let lineWidth: CGFloat = 1
		let posTop = colorPicker.bounds.maxY - (lineWidth / 2)
		let lineColor = NSColor.quaternaryLabelColor.cgColor

		let path = NSBezierPath()
		path.move(to: NSPoint(x: colorPicker.bounds.width, y: posTop))
		path.line(to: NSPoint(x: 0, y: posTop))
		let underscore = CAShapeLayer()
		underscore.strokeColor = lineColor
		underscore.lineWidth = lineWidth
		underscore.path = path.cgPath

		colorPicker.layer?.addSublayer(underscore)
	}

	private func swatch(size: NSSize, color: NSColor) -> NSImage {
		let image = NSImage(size: size)
		image.lockFocus()
		color.drawSwatch(in: NSMakeRect(0, 0, size.width, size.height))
		image.unlockFocus()

		return image
	}

	@IBAction func colorSelect(_ sender: NSPopUpButton) {
		if
			let title = sender.titleOfSelectedItem,
			let crayons = NSColorList.init(named: "Crayons"),
			let _ = crayons.color(withKey: title)
		{
			print(title)
//			let colorData = NSKeyedArchiver.archivedData(withRootObject: color)
//			userDefaults.set(colorData, forKey: "backgroundColorActiveTracking")
//			tracking.color = title

//			.filter({
//				if
//					let color = crayons.color(withKey: $0),
//					let red = color.usingColorSpace(.deviceRGB)?.redComponent,
//					let green = color.usingColorSpace(.deviceRGB)?.greenComponent,
//					let blue = color.usingColorSpace(.deviceRGB)?.blueComponent
//				{
//					return round(red * 100) != round(green * 100) || round(red * 100) != round(blue * 100)
//				}
//
//				return false
//			}) {
//				let item = NSMenuItem(title: key, action: nil, keyEquivalent: "")
//				item.image = swatch(size: size, color: crayons.color(withKey: key) ?? .red)
//				menu.addItem(item)
//			}
		}
	}

	@IBAction func jobSelect(_ sender: NSPopUpButton) {
		let title = sender.titleOfSelectedItem
		let currentActivity = activitySelect.titleOfSelectedItem
		guard let job = QuoJob.shared.jobs?.first(where: { "\($0.number!) - \($0.title!)" == title }) else {
			saveButton.isEnabled = false
			return
		}

		let type = job.type

		tempTracking.job = job
		saveButton.isEnabled = formIsValid

		taskSelect.removeAllItems()
		activitySelect.removeAllItems()

		if let tasks = QuoJob.shared.tasks {
			let taskTitles = tasks.filter({ $0.job!.id == job.id }).sorted(by: { $0.title! < $1.title! }).map({ $0.title })

			if (taskTitles.count > 0) {
				taskSelect.addItem(withTitle: "Aufgabe wählen")
				taskSelect.addItems(withTitles: taskTitles as! [String])
				taskSelect.isEnabled = true
			} else {
				taskSelect.isEnabled = false
			}
		}

		if let activities = QuoJob.shared.activities {
			let activityTitles = activities.filter({ ((type?.internal_service)! && $0.internal_service) || ((type?.productive_service)! && $0.external_service) }).sorted(by: { $0.title! < $1.title! }).map({ $0.title })
			activitySelect.addItem(withTitle: "Leistungsart wählen")
			activitySelect.addItems(withTitles: activityTitles as! [String])

			if let currentActivity = currentActivity, let currentIndex = activitySelect.itemTitles.firstIndex(of: currentActivity) {
				activitySelect.selectItem(at: currentIndex)
			} else {
				activitySelect.layer?.backgroundColor = NSColor.systemRed.withAlphaComponent(0.5).cgColor
			}
		}
	}

	@IBAction func taskSelect(_ sender: NSPopUpButton) {
		let title = sender.titleOfSelectedItem
		if let task = QuoJob.shared.tasks?.first(where: { $0.title == title }) {
			tempTracking.task = task
		} else {
			tempTracking.task = nil
		}
	}

	@IBAction func activitySelect(_ sender: NSPopUpButton) {
		let title = sender.titleOfSelectedItem
		guard let activity = QuoJob.shared.activities?.first(where: { $0.title == title }) else {
			saveButton.isEnabled = false
			return
		}

		activitySelect.layer?.backgroundColor = CGColor.clear
		tempTracking.activity = activity
		saveButton.isEnabled = formIsValid
	}

	@IBAction func deleteTracking(_ sender: NSButton) {
		guard let tracking = tracking else { return }
		context.delete(tracking)

		do {
			try context.save()
			removeFromParent()
		} catch let error {
			print(error)
		}
	}
	
	@IBAction func cancel(_ sender: NSButton) {
		removeFromParent()
	}

	@IBAction func save(_ sender: NSButton) {
		let currentTracking: Tracking!

		if let tracking = tracking {
			currentTracking = tracking
		} else {
			let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: context)
			currentTracking = NSManagedObject(entity: entity!, insertInto: context) as? Tracking
		}

		let mirror = Mirror(reflecting: tempTracking!)

		for (label, value) in mirror.children  {
			guard let label = label else { continue }

			if value is Job || value is Task || value is Activity || value is String || value is Date {
				currentTracking.setValue(value, forKey: label)
			}
		}

		currentTracking.setValue(tempTracking.job != nil ? SyncStatus.pending.rawValue : SyncStatus.error.rawValue, forKey: "exported")

		try? context.save()

		QuoJob.shared.exportTracking(tracking: currentTracking).done { result in
			if let hourbooking = result["hourbooking"] as? [String: Any], let id = hourbooking["id"] as? String {
				currentTracking.id = id
				currentTracking.exported = SyncStatus.success.rawValue
				try self.context.save()
			}
		}.catch { error in
			currentTracking.exported = SyncStatus.error.rawValue
			try? self.context.save()
			print(error)
		}

		removeFromParent()
	}

}
