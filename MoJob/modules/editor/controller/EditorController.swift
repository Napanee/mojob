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
	let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext

	var tracking: Tracking? {
		didSet {
			if let tracking = tracking {
				self.tempTracking = TempTracking(tracking: tracking)
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
		guard let tracking = tracking else { return }
		context.delete(tracking)

		if let _ = try? context.save() {
			removeFromParent()
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
			print(error)
			currentTracking.exported = SyncStatus.error.rawValue
			try? self.context.save()
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
