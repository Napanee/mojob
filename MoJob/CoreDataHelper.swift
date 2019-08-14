//
//  CoreDataHelper.swift
//  MoJob
//
//  Created by Martin Schneider on 06.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Foundation
import CoreData


class CoreDataHelper {

	static let context: NSManagedObjectContext = {
		let persistentContainer = CoreDataHelper.shared.persistentContainer
		let context = persistentContainer.viewContext

		return context
	}()

	static let backgroundContext: NSManagedObjectContext = {
		let parent = CoreDataHelper.context
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

		context.parent = parent

		return context
	}()

	var currentTracking: Tracking? {
		get {
			let context = CoreDataHelper.context
			let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()
			fetchRequest.predicate = NSPredicate(format: "date_end == nil")

			do {
				return try context.fetch(fetchRequest).first
			} catch let error as NSError {
				print("Could not fetch. \(error), \(error.userInfo)")
				return nil
			}
		}
	}

	var trackingsToday: [Tracking]? {
		get {
			let context = CoreDataHelper.context
			let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()

			var compoundPredicates = [NSPredicate]()
			compoundPredicates.append(NSPredicate(format: "date_end != nil"))

			if
				let todayStart = Date().startOfDay,
				let todayEnd = Date().endOfDay
			{
				let compound = NSCompoundPredicate(orPredicateWithSubpredicates: [
					NSPredicate(format: "date_start >= %@ AND date_start < %@", argumentArray: [todayStart, todayEnd]),
					NSPredicate(format: "date_end >= %@ AND date_end < %@", argumentArray: [todayStart, todayEnd])
					])
				compoundPredicates.append(compound)
			}

			fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicates)

			do {
				return try context.fetch(fetchRequest)
			} catch let error as NSError {
				print("Could not fetch. \(error), \(error.userInfo)")
				return nil
			}
		}
	}

	var trackingsWeek: [Tracking]? {
		get {
			let context = CoreDataHelper.context
			let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()

			var compoundPredicates = [NSPredicate]()
			compoundPredicates.append(NSPredicate(format: "date_end != nil"))

			if
				let weekStart = Date().startOfWeek,
				let weekEnd = Date().endOfWeek
			{
				let compound = NSCompoundPredicate(orPredicateWithSubpredicates: [
					NSPredicate(format: "date_start >= %@ AND date_start < %@", argumentArray: [weekStart, weekEnd]),
					NSPredicate(format: "date_end >= %@ AND date_end < %@", argumentArray: [weekStart, weekEnd])
				])
				compoundPredicates.append(compound)
			}

			fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicates)

			do {
				return try context.fetch(fetchRequest)
			} catch let error as NSError {
				print("Could not fetch. \(error), \(error.userInfo)")
				return nil
			}
		}
	}

	var secondsToday: Double? {
		let startOfDay = Date().startOfDay!
		let todayTrackings = trackingsToday?.map({ (tracking) -> TimeInterval in
			var dateStart = tracking.date_start!
			let dateEnd = tracking.date_end!

			if (tracking.date_start?.compare(startOfDay) == ComparisonResult.orderedAscending) {
				dateStart = startOfDay
			}

			return dateEnd.timeIntervalSince(dateStart)
		}).reduce(0, +)

		if let todayTrackings = todayTrackings {
			return todayTrackings
		}

		return 0
	}

	var secondsWeek: Double? {
		let startOfWeek = Date().startOfWeek!
		let weekTrackings = trackingsWeek?.map({ (tracking) -> TimeInterval in
			var dateStart = tracking.date_start!
			let dateEnd = tracking.date_end!

			if (tracking.date_start?.compare(startOfWeek) == ComparisonResult.orderedAscending) {
				dateStart = startOfWeek
			}

			return dateEnd.timeIntervalSince(dateStart)
		}).reduce(0, +)

		if let weekTrackings = weekTrackings {
			return weekTrackings
		}

		return 0
	}

	static let shared = CoreDataHelper()

	private init() {}

	lazy var persistentContainer: NSPersistentContainer = {
		/*
		The persistent container for the application. This implementation
		creates and returns a container, having loaded the store for the
		application to it. This property is optional since there are legitimate
		error conditions that could cause the creation of the store to fail.
		*/
		let modelURL = Bundle.main.url(forResource: RESSOURCE_NAME, withExtension: "momd") ?? Bundle.main.url(forResource: RESSOURCE_NAME, withExtension: "mom")
		let model = NSManagedObjectModel(contentsOf: modelURL!)
		let container = NSPersistentContainer(name: CONTAINER_NAME, managedObjectModel: model!)
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

				/*
				Typical reasons for an error here include:
				* The parent directory does not exist, cannot be created, or disallows writing.
				* The persistent store is not accessible, due to permissions or data protection when the device is locked.
				* The device is out of space.
				* The store could not be migrated to the current model version.
				Check the error message to determine what the actual problem was.
				*/
				fatalError("Unresolved error \(error)")
			}

			container.viewContext.automaticallyMergesChangesFromParent = true
		})
		return container
	}()

	static func saveContext() {
		do {
			try context.save()
		} catch let error as NSError  {
			print("Could not save \(error), \(error.userInfo)")
		}
	}

	static func trackings(for date: Date) -> [Tracking]? {
		let context = CoreDataHelper.context
		let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()

		var compoundPredicates = [NSPredicate]()
		compoundPredicates.append(NSPredicate(format: "date_end != nil"))

		if
			let todayStart = date.startOfDay,
			let todayEnd = date.endOfDay
		{
			let compound = NSCompoundPredicate(orPredicateWithSubpredicates: [
				NSPredicate(format: "date_start >= %@ AND date_start < %@", argumentArray: [todayStart, todayEnd]),
				NSPredicate(format: "date_end >= %@ AND date_end < %@", argumentArray: [todayStart, todayEnd])
				])
			compoundPredicates.append(compound)
		}

		fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicates)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date_start", ascending: true)]

		do {
			return try context.fetch(fetchRequest)
		} catch let error as NSError {
			print("Could not fetch. \(error), \(error.userInfo)")
			return nil
		}
	}

	static func seconds(for date: Date) -> Double? {
		let startOfDay = date.startOfDay!
		let todayTrackings = CoreDataHelper.trackings(for: date)?.map({ (tracking) -> TimeInterval in
			var dateStart = tracking.date_start!
			let dateEnd = tracking.date_end!

			if (tracking.date_start?.compare(startOfDay) == ComparisonResult.orderedAscending) {
				dateStart = startOfDay
			}

			return dateEnd.timeIntervalSince(dateStart)
		}).reduce(0, +)

		if let todayTrackings = todayTrackings {
			return todayTrackings
		}

		return 0
	}

}
