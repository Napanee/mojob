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
	
	private var currentDate: Date? {
		didSet {
			let calendar = Calendar.current
			let components = calendar.dateComponents([.month, .year], from: currentDate!)
			currentMonth.stringValue = "\(calendar.monthSymbols[components.month! - 1]) \(components.year!)"

			let isCurrentMonth = currentDate!.isInMonth(of: Date())
			nextMonthButton.isEnabled = !isCurrentMonth
			nextYearButton.isEnabled = !isCurrentMonth

			calendarGridView.reloadData(withDate: currentDate!)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		currentDate = Date()
		calendarGridView.reloadData(withDate: currentDate!)

		let context = CoreDataHelper.context
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

	// MARK: - Observer

	@objc func managedObjectContextDidSave(notification: NSNotification) {
		guard let userInfo = notification.userInfo else { return }

		if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
			calendarGridView.reloadData(withDate: currentDate!)
		}

		if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
			calendarGridView.reloadData(withDate: currentDate!)
		}

		if let deletes = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deletes.count > 0 {
			calendarGridView.reloadData(withDate: currentDate!)
		}
	}

}
