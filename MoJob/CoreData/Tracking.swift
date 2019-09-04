//
//  Tracking.swift
//  MoJob
//
//  Created by Martin Schneider on 06.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit


extension Tracking {

	var duration: TimeInterval {
		return (self.date_end ?? Date()).timeIntervalSince(self.date_start ?? Date())
	}

	var isValid: Bool {
		get {
			return self.activity != nil &&
				(self.job != nil || self.custom_job != nil)
		}
	}

	func stop(dateEnd: Date? = nil) {
		if let date_start = date_start, Date().timeIntervalSince(date_start) < 60 {
			let question = "Tracking wird verworfen. Möchtest du fortfahren?"
			let info = "QuoJob akzeptiert nur Trackings, die mindestens eine Minute dauern."
			let confirmButton = "Tracking verwerfen"
			let cancelButton = "Abbrechen"
			let alert = NSAlert()
			alert.messageText = question
			alert.informativeText = info
			alert.addButton(withTitle: confirmButton)
			alert.addButton(withTitle: cancelButton)

			let answer = alert.runModal()
			if answer == .alertSecondButtonReturn {
				return
			} else {
				managedObjectContext?.reset()

				NotificationCenter.default.post(name: NSNotification.Name(rawValue: "counter:tick"), object: nil)
			}
		} else {
			let date = dateEnd ?? Date()

			self.exported = SyncStatus.pending.rawValue
			self.date_start = Calendar.current.date(bySetting: .second, value: 0, of: self.date_start ?? date)
			self.date_end = Calendar.current.date(bySetting: .second, value: 0, of: date)

			CoreDataHelper.save(in: managedObjectContext)

			if let _ = self.job {
				self.export()
			}
		}

		GlobalTimer.shared.startNoTrackingTimer()
		GlobalTimer.shared.stopTimer()
		(NSApp.mainWindow?.windowController as? MainWindowController)?.mainSplitViewController?.removeTracking()
	}

	func delete() {
		if (self.id != nil) {
			deleteFromServer().done({ _ in
				self.deleteLocal()
			}).catch({ _ in })
		} else {
			self.deleteLocal()
		}
	}

	func deleteLocal() {
		managedObjectContext?.delete(self)
		CoreDataHelper.save(in: managedObjectContext)
	}

	func deleteFromServer() -> Promise<Void>{
		return QuoJob.shared.deleteTracking(tracking: self)
	}

	func export() {
		guard let tracking = CoreDataHelper.tracking(with: objectID) else { return }

		QuoJob.shared.exportTracking(tracking: self).done({ id in
			tracking.id = id
			tracking.exported = SyncStatus.success.rawValue
			tracking.sync = Calendar.current.date(bySetting: .nanosecond, value: 0, of: Date())

			CoreDataHelper.save()
		}).catch { error in
			tracking.exported = SyncStatus.error.rawValue
			CoreDataHelper.save()
		}
	}

}
