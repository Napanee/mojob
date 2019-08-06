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

			tracking.setValue(Date(), forKey: "date_start")

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
		return Promise { _ in
			let context = CoreDataHelper.shared.persistentContainer.viewContext

			for (key, value) in params {
				setValue(value, forKey: key)
			}

			do {
				try context.save()
			} catch let error as NSError  {
				print("Could not save \(error), \(error.userInfo)")
			}
		}
	}

	func delete() {
		let context = CoreDataHelper.shared.persistentContainer.viewContext

		context.delete(self)

		do {
			try context.save()
		} catch let error as NSError {
			print("Could not delete \(error), \(error.userInfo)")
		}
	}

	func export() -> Promise<Void> {
		return Promise { _ in
			QuoJob.shared.exportTracking(tracking: self).done { result in
				if let hourbooking = result["hourbooking"] as? [String: Any], let id = hourbooking["id"] as? String {
					self.update(with: ["id": id, "exported": SyncStatus.success.rawValue]).catch({ error in
						print(error)
					})
				}
			}.catch { _ in
				self.update(with: ["exported": SyncStatus.error.rawValue]).catch({ error in
					print(error)
				})
			}
		}
	}

}
