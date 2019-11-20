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

	static let mainContext: NSManagedObjectContext = {
		let persistentContainer = CoreDataHelper.shared.persistentContainer
		let context = persistentContainer.viewContext

		return context
	}()

	static let backgroundContext: NSManagedObjectContext = {
		let parent = CoreDataHelper.mainContext
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

		context.automaticallyMergesChangesFromParent = true
		context.parent = parent

		return context
	}()

	static let currentTrackingContext: NSManagedObjectContext = {
		let parent = CoreDataHelper.mainContext
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

		context.automaticallyMergesChangesFromParent = true
		context.parent = parent

		return context
	}()

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

	static func save(in context: NSManagedObjectContext? = nil) {
		let context = context ?? mainContext

		guard context.hasChanges else { return }

		do {
			try context.save()

			if (context != mainContext) {
				do {
					try mainContext.save()
				} catch let error as NSError  {
					print("Could not save \(error), \(error.userInfo)")
				}
			}
		} catch let error as NSError  {
			print("Could not save \(error), \(error.userInfo)")
		}
	}

	static func jobs(in context: NSManagedObjectContext? = nil) -> [Job] {
		var result: [Job] = []
		let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "title", ascending: false)
		]
		let predicates = NSCompoundPredicate(andPredicateWithSubpredicates: [
			NSPredicate(format: "assigned = %@", argumentArray: [true]),
			NSPredicate(format: "bookable = %@", argumentArray: [true])
			])
		fetchRequest.predicate = predicates

		do {
			result = try (context ?? self.mainContext).fetch(fetchRequest)
		} catch let error {
			print(error)
		}

		return result
	}

	static func activities(in context: NSManagedObjectContext? = nil) -> [Activity] {
		var result: [Activity] = []
		let fetchRequest: NSFetchRequest<Activity> = Activity.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "title", ascending: false)
		]

		do {
			result = try (context ?? self.mainContext).fetch(fetchRequest)
		} catch let error {
			print(error)
		}

		return result
	}

	static func favorites(in context: NSManagedObjectContext? = nil) -> [Favorite] {
		var result: [Favorite] = []
		let fetchRequest: NSFetchRequest<Favorite> = Favorite.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "order", ascending: true)
		]

		do {
			result = try (context ?? self.mainContext).fetch(fetchRequest)
		} catch let error {
			print(error)
		}

		return result
	}

	static func tasks(in context: NSManagedObjectContext? = nil) -> [Task] {
		var result: [Task] = []
		let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "title", ascending: false)
		]
		fetchRequest.predicate = NSPredicate(format: "done = %@", argumentArray: [false])

		do {
			result = try (context ?? self.mainContext).fetch(fetchRequest)
		} catch let error {
			print(error)
		}

		return result
	}

	static func types(in context: NSManagedObjectContext? = nil) -> [Type] {
		var result: [Type] = []
		let fetchRequest: NSFetchRequest<Type> = Type.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "title", ascending: false)
		]

		do {
			result = try (context ?? self.mainContext).fetch(fetchRequest)
		} catch let error {
			print(error)
		}

		return result
	}

	static func trackings(in context: NSManagedObjectContext? = nil) -> [Tracking] {
		var result: [Tracking] = []
		let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "id", ascending: false)
		]

		do {
			result = try (context ?? self.mainContext).fetch(fetchRequest)
		} catch let error {
			print(error)
		}

		return result
	}

	static func resetData() {
		let uniqueNames = CoreDataHelper.shared.persistentContainer.managedObjectModel.entities.compactMap({ $0.name })

		uniqueNames.forEach { (name) in
			let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
			let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

			do {
				try CoreDataHelper.shared.persistentContainer.viewContext.execute(batchDeleteRequest)
			} catch {
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}

}

// MARK: - Favorites
extension CoreDataHelper {

	static func favorite(job: Job?, task: Task?, activity: Activity?) -> Favorite? {
		let job = CoreDataHelper.jobs().first(where: { $0.id == job?.id })
		let task = CoreDataHelper.tasks().first(where: { $0.id == task?.id })
		let activity = CoreDataHelper.activities().first(where: { $0.id == activity?.id })
		return self.favorites().first(where: { $0.job == job && $0.task == task && $0.activity == activity })
	}

	static func createFavorite(job: Job?, task: Task?, activity: Activity?) {
		let favoritesCount = favorites().count
		let entity = NSEntityDescription.entity(forEntityName: "Favorite", in: mainContext)
		let favorite = NSManagedObject(entity: entity!, insertInto: mainContext)

		favorite.setValue(favoritesCount, forKey: "order")

		if let job = jobs().first(where: { $0.id == job?.id }) {
			favorite.setValue(job, forKey: "job")
		}

		if let activity = activities().first(where: { $0.id == activity?.id }) {
			favorite.setValue(activity, forKey: "activity")
		}

		if let task = CoreDataHelper.tasks().first(where: { $0.id == task?.id }) {
			favorite.setValue(task, forKey: "task")
		}

		CoreDataHelper.save()
	}

	static func deleteFavorite(job: Job?, task: Task?, activity: Activity?) {
		if let favorite = favorite(job: job, task: task, activity: activity) {
			deleteFavorite(favorite: favorite)
		}
	}

	static func deleteFavorite(favorite: Favorite) {
		mainContext.delete(favorite)
		save()
	}

}

// MARK: - Trackings
extension CoreDataHelper {

	static var currentTracking: Tracking? {
		get {
			let context = CoreDataHelper.currentTrackingContext
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

	static func createTracking(in context: NSManagedObjectContext? = nil) -> Tracking? {
		if let currentTracking = currentTracking, context == currentTrackingContext {
			currentTracking.stop()

			if let _ = self.currentTracking {
				return nil
			}
		}

		let context = (context ?? self.mainContext)
		let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: context)
		let tracking = NSManagedObject(entity: entity!, insertInto: context)

		tracking.setValue(Date(), forKey: "date_start")

		let userDefaults = UserDefaults()
		if
			let activityId = userDefaults.string(forKey: UserDefaults.Keys.activity),
			let activity = activities(in: context).first(where: { $0.id == activityId })
		{
			tracking.setValue(activity, forKey: UserDefaults.Keys.activity)
		}

		if (context == currentTrackingContext) {
			GlobalTimer.shared.startTimer()
		}

		return tracking as? Tracking
	}

	static func tracking(with objectId: NSManagedObjectID) -> Tracking? {
		let context = CoreDataHelper.mainContext
		let tracking = context.object(with: objectId)

		return tracking as? Tracking
	}

	static func trackings(from dateStart: Date, byAdding component: Calendar.Component, and job: Job? = nil) -> [Tracking]? {
		var trackings: [Tracking] = []
		let context = CoreDataHelper.mainContext
		let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()

		var compoundPredicates = [NSPredicate]()

		if let job = job {
			compoundPredicates.append(NSPredicate(format: "job == %@", argumentArray: [job]))
		}

		let dateUntil = Calendar.current.date(byAdding: component, value: 1, to: dateStart)!
		let compound = NSCompoundPredicate(orPredicateWithSubpredicates: [
			NSPredicate(format: "date_start >= %@ AND date_start < %@", argumentArray: [dateStart, dateUntil]),
			NSPredicate(format: "date_end >= %@ AND date_end < %@", argumentArray: [dateStart, dateUntil]),
			NSPredicate(format: "date_start >= %@ AND date_start < %@ AND date_end == nil", argumentArray: [dateStart, dateUntil])
		])
		compoundPredicates.append(compound)

		fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: compoundPredicates)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date_start", ascending: true)]

		do {
			trackings = try context.fetch(fetchRequest)
		} catch let error as NSError {
			print("Could not fetch. \(error), \(error.userInfo)")
			return nil
		}

		if let currentTracking = currentTracking, Calendar.current.isDate(currentTracking.date_start!, inSameDayAs: dateStart) {
			trackings.append(currentTracking)
		}

		return trackings
	}

	static func seconds(from dateStart: Date, byAdding component: Calendar.Component, and job: Job? = nil) -> Double? {
		let todayTrackings = CoreDataHelper.trackings(from: dateStart, byAdding: component, and: job)?.map({ (tracking) -> TimeInterval in
			var trackingDateStart = tracking.date_start!
			let trackingDateEnd = tracking.date_end ?? Date()

			if (trackingDateStart.compare(dateStart) == ComparisonResult.orderedAscending) {
				trackingDateStart = dateStart
			}

			return trackingDateEnd.timeIntervalSince(trackingDateStart)
		}).reduce(0, +)

		if let todayTrackings = todayTrackings {
			return todayTrackings
		}

		return 0
	}

}
