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

	class func insert(with params: [String: Any?]) -> Promise<Tracking?> {
		return Promise { seal in
			let context = CoreDataHelper.context
			let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: context)
			let tracking = NSManagedObject(entity: entity!, insertInto: context)

			tracking.setValue(Date(), forKey: "date_start")

			for (key, value) in params {
				tracking.setValue(value, forKey: key)
			}

			let userDefaults = UserDefaults()
			if let activityId = userDefaults.string(forKey: UserDefaults.Keys.activity), let activity = QuoJob.shared.activities.first(where: { $0.id == activityId }) {
				tracking.setValue(activity, forKey: UserDefaults.Keys.activity)
			}

			do {
				try context.save()

				seal.fulfill(tracking as? Tracking)
			} catch let error as NSError {
				seal.reject(error)
			}
		}
	}

//	func update(with params: [String: Any?]) {
//		let context = CoreDataHelper.shared.persistentContainer.viewContext
//
//		for (key, value) in params {
//			setValue(value, forKey: key)
//		}
//
//		do {
//			try context.save()
//		} catch let error as NSError  {
//			print("Could not save \(error), \(error.userInfo)")
//		}
//	}

	func stop(dateEnd: Date? = nil) {
		let date = dateEnd ?? Date()

		self.update(with: [
			"exported": SyncStatus.pending.rawValue,
			"date_start": Calendar.current.date(bySetting: .second, value: 0, of: self.date_start ?? date),
			"date_end": Calendar.current.date(bySetting: .second, value: 0, of: date)
		]).done({ _ in
			if let _ = self.job {
				self.export()
			}

			GlobalTimer.shared.startNoTrackingTimer()
		}).catch { error in print(error) }

		GlobalTimer.shared.stopTimer()
	}

	func update(with params: [String: Any?]) -> Promise<Void> {
		return Promise { seal in
			let context = CoreDataHelper.context

			for (key, value) in params {
				setValue(value, forKey: key)
			}

			do {
				try context.save()
				seal.fulfill_()
			} catch let error as NSError  {
				print("Could not save \(error), \(error.userInfo)")
				seal.reject(error)
			}
		}
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
		let context = CoreDataHelper.context

		context.delete(self)

		do {
			try context.save()
		} catch let error as NSError {
			print("Could not delete \(error), \(error.userInfo)")
		}
	}

	func deleteFromServer() -> Promise<Void>{
		return QuoJob.shared.deleteTracking(tracking: self)
	}

	func export() {
		QuoJob.shared.exportTracking(tracking: self).catch { error in
			self.update(with: ["exported": SyncStatus.error.rawValue]).done({ _ in }).catch({ _ in })
		}
	}

}
