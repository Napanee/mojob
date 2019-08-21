//
//  CalendarController.swift
//  MoJob
//
//  Created by Martin Schneider on 10.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class CalendarController: NSViewController {

	@IBOutlet weak var calendarGridView: CalendarGridView!
	@IBOutlet weak var nextMonthButton: NSButton!
	@IBOutlet weak var nextYearButton: NSButton!
	@IBOutlet weak var currentMonth: NSTextField!
	@IBOutlet weak var todayButton: NSButton!
	@IBOutlet weak var jobSelect: NSComboBox!

	let calendar = Calendar.current
	var jobs: [Job] = []
	var monitor: Any?

	private var currentDate: Date? {
		didSet {
			guard let currentDate = currentDate else { return }

			let components = calendar.dateComponents([.month, .year], from: currentDate)
			currentMonth.stringValue = "\(calendar.monthSymbols[components.month! - 1]) \(components.year!)"

			let isCurrentMonth = calendar.date(Date(), matchesComponents: components)
			nextMonthButton.isEnabled = !isCurrentMonth
			nextYearButton.isEnabled = !isCurrentMonth

			calendarGridView.reloadData(for: components)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		initJobSelect()

		currentDate = Date()
		calendarGridView.reloadData(for: calendar.dateComponents([.month, .year], from: currentDate!))

		todayButton.wantsLayer = true
		todayButton.layer?.borderWidth = 1
		todayButton.layer?.cornerRadius = 16
		todayButton.layer?.borderColor = NSColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 0.7).cgColor

		monitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
			let location = NSPoint(x: self.view.window!.mouseLocationOutsideOfEventStream.x, y: self.view.window!.mouseLocationOutsideOfEventStream.y)
			let frame = self.calendarGridView.gradientCircle.frame
			var localPoint = self.calendarGridView.convert(location, from: nil)

			localPoint.x -= frame.width / 2
			localPoint.y -= frame.height / 2
			self.calendarGridView.gradientCircle.frame.origin = CGPoint(x: localPoint.x + $0.deltaX, y: localPoint.y - $0.deltaY)

			return $0
		}

		let context = CoreDataHelper.mainContext
		let notificationCenter = NotificationCenter.default
		notificationCenter.addObserver(self, selector: #selector(managedObjectContextDidSave), name: NSNotification.Name.NSManagedObjectContextDidSave, object: context)
	}

	override func viewDidAppear() {
		super.viewDidAppear()

		view.addConstraints([
			NSLayoutConstraint(item: calendarGridView!, attribute: .width, relatedBy: .equal, toItem: calendarGridView.superview, attribute: .width, multiplier: 1, constant: 0),
			NSLayoutConstraint(item: calendarGridView!, attribute: .height, relatedBy: .equal, toItem: calendarGridView.superview, attribute: .height, multiplier: 1, constant: 0)
		])
	}

	override func viewDidDisappear() {
		NSEvent.removeMonitor(monitor as Any)
	}

	private func initJobSelect() {
		jobSelect.placeholderString = "Job filtern"

		self.jobs = CoreDataHelper.jobs()
			.sorted(by: { $0.number! != $1.number! ? $0.number! < $1.number! : $0.title! < $1.title! })

		jobSelect.reloadData()
	}

	@IBAction func jobSelect(_ sender: NSComboBox) {
		guard let cell = sender.cell else { return }

		let value = cell.stringValue.lowercased()

		if let job = CoreDataHelper.jobs().first(where: { $0.fullTitle.lowercased() == value }) {
			calendarGridView.job = job
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "calendar:changedDate"), object: ["day": currentDate as Any, "job": job as Any])
		} else {
			calendarGridView.job = nil
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "calendar:changedDate"), object: ["day": currentDate as Any])
		}
	}

	@IBAction func prevMonthButton(_ sender: NSButton) {
		currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate ?? Date())!
	}

	@IBAction func nextMonthButton(_ sender: NSButton) {
		currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate ?? Date())!
	}

	@IBAction func prevYearButton(_ sender: NSButton) {
		currentDate = Calendar.current.date(byAdding: .year, value: -1, to: currentDate ?? Date())!
	}

	@IBAction func nextYearButton(_ sender: NSButton) {
		let nextDate = Calendar.current.date(byAdding: .year, value: 1, to: currentDate ?? Date())!
		currentDate = nextDate.compare(Date()) == ComparisonResult.orderedAscending ? nextDate : Date()
	}

	@IBAction func todayButton(_ sender: NSButton) {
		currentDate = Date()
	}

	// MARK: - Observer

	@objc func managedObjectContextDidSave(notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }

		if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
			calendarGridView.reloadData(for: calendar.dateComponents([.month, .year], from: currentDate!))
		}

		if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
			calendarGridView.reloadData(for: calendar.dateComponents([.month, .year], from: currentDate!))
		}

		if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
			calendarGridView.reloadData(for: calendar.dateComponents([.month, .year], from: currentDate!))
		}
	}

}

extension CalendarController: NSComboBoxDataSource {

	func numberOfItems(in comboBox: NSComboBox) -> Int {
		if (comboBox.isEqual(jobSelect)) {
			return jobs.count
		}

		return 0
	}

	func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
		if (comboBox.isEqual(jobSelect)) {
			let job = jobs[index]
			return job.fullTitle
		}

		return ""
	}

}

extension CalendarController: NSTextFieldDelegate {
	func controlTextDidChange(_ obj: Notification) {
		if let comboBox = obj.object as? NSComboBox {
			handleTextChange(in: comboBox)
		}
	}

	private func handleTextChange(in comboBox: NSComboBox) {
		guard let comboBoxCell = comboBox.cell as? NSComboBoxCell else { return }
		let value = comboBoxCell.stringValue.lowercased()

		if (comboBox.isEqual(jobSelect)) {
			jobs = CoreDataHelper.jobs()
				.filter({ value == "" || $0.fullTitle.lowercased().contains(value) })
				.sorted(by: { $0.number! != $1.number! ? $0.number! < $1.number! : $0.title! < $1.title! })

			if (jobs.count > 0) {
				comboBoxCell.perform(Selector(("popUp:")))
			}
		}

		comboBox.reloadData()
	}
}
