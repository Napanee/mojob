//
//  DeleteFavoritePolicy.swift
//  MoJob
//
//  Created by Martin Schneider on 24.11.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class DeleteFavoritePolicy: NSEntityMigrationPolicy {

	override func begin(_ mapping: NSEntityMapping, with manager: NSMigrationManager) throws {
		let entityName = "Favorite"
		let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
		let context = manager.sourceContext
		let results = try context.fetch(request)
		results.forEach(context.delete)
		try super.begin(mapping, with: manager)
	}

}
