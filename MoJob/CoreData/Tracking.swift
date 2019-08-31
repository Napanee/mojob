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
		let date = dateEnd ?? Date()

		self.exported = SyncStatus.pending.rawValue
		self.date_start = Calendar.current.date(bySetting: .second, value: 0, of: self.date_start ?? date)
		self.date_end = Calendar.current.date(bySetting: .second, value: 0, of: date)

		CoreDataHelper.save(in: managedObjectContext)

		if let _ = self.job {
			self.export()
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
