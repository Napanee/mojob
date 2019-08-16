//
//  DeleteTaskPolicy.swift
//  MoJob
//
//  Created by Martin Schneider on 15.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class DeleteTaskPolicy: NSEntityMigrationPolicy {

	override func begin(_ mapping: NSEntityMapping, with manager: NSMigrationManager) throws {
		let entityName = "Task"
		let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
		let context = manager.sourceContext
		let results = try context.fetch(request)
		results.forEach(context.delete)
		try super.begin(mapping, with: manager)
	}

}
