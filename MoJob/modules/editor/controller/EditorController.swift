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

class EditorController: QuoJobSelections {
	let context = CoreDataHelper.shared.persistentContainer.viewContext

	var sourceTracking: Tracking? {
		didSet {
			if let sourceTracking = sourceTracking {
				self.tempTracking = TempTracking(tracking: sourceTracking)
			}
		}
	}

	override var formIsValid: Bool {
		get { return super.formIsValid }
		set { saveButton.isEnabled = newValue && super.formIsValid }
	}

	@IBOutlet weak var saveButton: NSButton!
	@IBOutlet weak var deleteButton: NSButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		saveButton.isEnabled = formIsValid
		deleteButton.isHidden = tracking == nil
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

	@IBAction func deleteTracking(_ sender: NSButton) {
		guard let sourceTracking = sourceTracking else { return }
		sourceTracking.delete()

		removeFromParent()
	}
	
	@IBAction func cancel(_ sender: NSButton) {
		removeFromParent()
	}

	@IBAction func save(_ sender: NSButton) {
		var values: [String: Any] = [:]

		let mirror = Mirror(reflecting: tempTracking!)

		for (label, value) in mirror.children  {
			guard let label = label else { continue }

			if value is Job || value is Task || value is Activity || value is String || value is Date {
				values[label] = value
			}
		}

		values["exported"] = tempTracking?.job != nil ? SyncStatus.pending.rawValue : SyncStatus.error.rawValue

		if let sourceTracking = sourceTracking {
			sourceTracking.update(with: values).done({ _ in
				if let _ = sourceTracking.job {
					sourceTracking.export().catch({ error in print(error) })
				}
			}).catch { error in print(error) }
		} else {
			Tracking.insert(with: values).done({ tracking in
				tracking?.export().catch({ error in print(error) })
			}).catch({ _ in })
		}

		removeFromParent()
	}

}

extension EditorController: DateFieldDelegate {

	func getFromMonth() -> Int? {
		return Int(fromMonth!.stringValue)
	}

	func getFromYear() -> Int? {
		return Int(fromYear!.stringValue)
	}

	func getUntilMonth() -> Int? {
		return Int(untilMonth!.stringValue)
	}

	func getUntilYear() -> Int? {
		return Int(untilYear!.stringValue)
	}

}
