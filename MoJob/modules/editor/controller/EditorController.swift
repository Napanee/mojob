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
}

class EditorController: QuoJobSelections {

	override var formIsValid: Bool {
		get { return super.formIsValid }
		set { saveButton.isEnabled = newValue && super.formIsValid }
	}

	@IBOutlet weak var saveButton: NSButton!
	@IBOutlet weak var deleteButton: NSButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		saveButton.isEnabled = formIsValid
		deleteButton.isHidden = tracking?.managedObjectContext == CoreDataHelper.backgroundContext
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
		tracking?.delete()

		removeFromParent()
	}
	
	@IBAction func cancel(_ sender: NSButton) {
		removeFromParent()
	}

	@IBAction func save(_ sender: NSButton) {
		guard let tracking = tracking else { return }

		if (tracking.job != nil) {
			tracking.exported = SyncStatus.pending.rawValue
			tracking.save()
		}

		if let _ = tracking.job {
			tracking.export()
		} else if let _ = tracking.id {
			tracking.deleteFromServer().done({ _ in
				tracking.update(with: ["id": nil, "exported": nil]).done({ _ in }).catch({ _ in })
			}).catch({ error in
				tracking.update(with: ["exported": SyncStatus.error.rawValue]).done({ _ in }).catch({ _ in })
			})
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

}
