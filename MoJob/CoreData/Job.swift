//
//  Job.swift
//  MoJob
//
//  Created by Martin Schneider on 06.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit


extension Job {

//	class func insert(with params: [String: Any]) -> Tracking? {
//		let context = CoreDataHelper.shared.persistentContainer.viewContext
//		let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: context)
//		let tracking = NSManagedObject(entity: entity!, insertInto: context)
//
//		tracking.setValuesForKeys(params)
//
//		do {
//			try context.save()
//			return tracking as? Tracking
//		} catch let error as NSError {
//			print("Could not save. \(error), \(error.userInfo)")
//			return nil
//		}
//	}

	var fullTitle: String {
		get {
			return "\(self.number ?? "no number") - \(self.title ?? "no title")"
		}
	}

	func update(with params: [String: Any?]) {
		for (key, value) in params {
			setValue(value, forKey: key)
		}
	}

//	func delete() {
//		let context = CoreDataHelper.shared.persistentContainer.viewContext
//
//		context.delete(self)
//
//		do {
//			try context.save()
//		} catch let error as NSError {
//			print("Could not delete \(error), \(error.userInfo)")
//		}
//	}

}

