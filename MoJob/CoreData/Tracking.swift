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

	var isValid: Bool {
		get {
			return self.activity != nil &&
				(self.date_end ?? Date()).timeIntervalSince(self.date_start ?? Date()) > 60 &&
				(self.job != nil || self.custom_job != nil)
		}
	}

	class func insert(with params: [String: Any]) -> Promise<Tracking?> {
		return Promise { seal in
			let context = CoreDataHelper.shared.persistentContainer.viewContext
			let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: context)
			let tracking = NSManagedObject(entity: entity!, insertInto: context)

			for (key, value) in params {
				tracking.setValue(value, forKey: key)
			}

			tracking.setValue(Calendar.current.date(bySetting: .second, value: 0, of: params["date_start"] as? Date ?? Date())!, forKey: "date_start")

			let userDefaults = UserDefaults()
			if let activityId = userDefaults.string(forKey: "activity"), let activity = QuoJob.shared.activities?.first(where: { $0.id == activityId }) {
				tracking.setValue(activity, forKey: "activity")
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

	func update(with params: [String: Any?]) -> Promise<Void> {
		return Promise { seal in
			let context = CoreDataHelper.shared.persistentContainer.viewContext

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
		QuoJob.shared.deleteTracking(tracking: self)
			.done({ result in
				if let success = result["success"] as? Bool, success == true {
					let context = CoreDataHelper.shared.persistentContainer.viewContext

					context.delete(self)

					do {
						try context.save()
					} catch let error as NSError {
						print("Could not delete \(error), \(error.userInfo)")
					}
				}
			})
			.catch({ _ in })
	}

	func export() -> Promise<Void> {
		return Promise { seal in
			QuoJob.shared.exportTracking(tracking: self).done({ _ in
				seal.fulfill_()
			}).catch { error in
				seal.reject(error)
				self.update(with: ["exported": SyncStatus.error.rawValue]).done({ _ in }).catch({ _ in })
			}
		}
	}

}
