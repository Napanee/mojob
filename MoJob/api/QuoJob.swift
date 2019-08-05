//
//  QuoJob.swift
//  MoJob
//
//  Created by Martin Schneider on 24.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import PromiseKit
import Alamofire
import Foundation
import KeychainAccess


enum ApiError: Error {
	case withMessage(String)
	case other(Int)
}

extension ApiError: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .withMessage(let message):
			return NSLocalizedString(message, comment: "")
		case .other(let statusCode):
			return NSLocalizedString("Fehlercode: \(statusCode)", comment: "")
		}
	}
}


class QuoJob {

	static let shared = QuoJob()

	let dateFormatterFull = DateFormatter()
	let dateFormatterTime = DateFormatter()

	var jobs: [Job]? {
		get {
			try? fetchedResultControllerJob.performFetch()
			return fetchedResultControllerJob.fetchedObjects?.filter({ $0.assigned })
		}
	}

	var activities: [Activity]? {
		get {
			try? fetchedResultControllerActivity.performFetch()
			return fetchedResultControllerActivity.fetchedObjects
		}
	}

	var tasks: [Task]? {
		get {
			try? fetchedResultControllerTask.performFetch()
			return fetchedResultControllerTask.fetchedObjects
		}
	}

	var lastSync: Sync? = nil
	var keychain: Keychain!
	var userId: String!
	var sessionId: String! = "" {
		didSet {
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateSession"), object: nil)
		}
	}

	let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
	var _fetchedResultsControllerSync: NSFetchedResultsController<Sync>? = nil
	var fetchedResultControllerSync: NSFetchedResultsController<Sync> {
		if (_fetchedResultsControllerSync != nil) {
			return _fetchedResultsControllerSync!
		}

		let fetchRequest: NSFetchRequest<Sync> = Sync.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "jobs", ascending: false)
		]

		let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsControllerSync = resultsController

		do {
			try _fetchedResultsControllerSync!.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror)")
		}

		return _fetchedResultsControllerSync!
	}

	var _fetchedResultsControllerActivity: NSFetchedResultsController<Activity>? = nil
	var fetchedResultControllerActivity: NSFetchedResultsController<Activity> {
		if (_fetchedResultsControllerActivity != nil) {
			return _fetchedResultsControllerActivity!
		}

		let fetchRequest: NSFetchRequest<Activity> = Activity.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "title", ascending: false)
		]

		let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsControllerActivity = resultsController

		do {
			try _fetchedResultsControllerActivity!.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror)")
		}

		return _fetchedResultsControllerActivity!
	}

	var _fetchedResultsControllerJob: NSFetchedResultsController<Job>? = nil
	var fetchedResultControllerJob: NSFetchedResultsController<Job> {
		if (_fetchedResultsControllerJob != nil) {
			return _fetchedResultsControllerJob!
		}

		let fetchRequest: NSFetchRequest<Job> = Job.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "title", ascending: false)
		]

		let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsControllerJob = resultsController

		do {
			try _fetchedResultsControllerJob!.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror)")
		}

		return _fetchedResultsControllerJob!
	}

	var _fetchedResultsControllerTask: NSFetchedResultsController<Task>? = nil
	var fetchedResultControllerTask: NSFetchedResultsController<Task> {
		if (_fetchedResultsControllerTask != nil) {
			return _fetchedResultsControllerTask!
		}

		let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "title", ascending: false)
		]

		let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsControllerTask = resultsController

		do {
			try _fetchedResultsControllerTask!.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror)")
		}

		return _fetchedResultsControllerTask!
	}

	var _fetchedResultsControllerType: NSFetchedResultsController<Type>? = nil
	var fetchedResultControllerType: NSFetchedResultsController<Type> {
		if (_fetchedResultsControllerType != nil) {
			return _fetchedResultsControllerType!
		}

		let fetchRequest: NSFetchRequest<Type> = Type.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "title", ascending: false)
		]

		let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsControllerType = resultsController

		do {
			try _fetchedResultsControllerType!.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror)")
		}

		return _fetchedResultsControllerType!
	}

	private init() {
		lastSync = fetchedResultControllerSync.fetchedObjects?.first

		dateFormatterFull.dateFormat = "YYYYMMddHHmmss"
		dateFormatterTime.dateFormat = "HHmm"
	}

	func fetch(params: [String: Any]) -> Promise<[String: Any]> {
		return Promise { seal in
			Alamofire.request(API_URL, method: .post, parameters: params, encoding: JSONEncoding.default)
				.responseJSON { response in
					switch response.result {
					case .success(let json):
						guard let json = json as? [String: Any] else {
							return seal.reject(AFError.responseValidationFailed(reason: .dataFileNil))
						}

						if let error = json["error"] as? [String: Any] {
							var statusCode: Int = 0
							if let statusCodeString = error["code"] as? NSString {
								statusCode = statusCodeString.integerValue
							} else if let statusCodeInt = error["code"] as? Int {
								statusCode = statusCodeInt
							}

							switch statusCode {
							case 1000: // No right for the requestes action
								seal.reject(ApiError.withMessage(errorMessages.missingRights))
							case 2001: // User NOT found
								seal.reject(ApiError.withMessage(errorMessages.notFound))
							case 2002: // Wrong password
								seal.reject(ApiError.withMessage(errorMessages.wrongPassword))
							case 2003, 2004: // No session given, Invalid session
								seal.reject(ApiError.withMessage(errorMessages.sessionProblem))
							case 2011: // User account is disabled
								seal.reject(ApiError.withMessage(errorMessages.disabled))
							case 4001: // Hourbooking is NOT editable
								seal.reject(ApiError.withMessage("Hourbooking is NOT editable"))
							default:
								seal.reject(ApiError.other(statusCode))
							}
						} else if let result = json["result"] as? [String: Any] {
							seal.fulfill(result)
						}

						seal.reject(ApiError.withMessage(errorMessages.unknown))
					case .failure(let error):
						switch error.localizedDescription {
						case "A server with the specified hostname could not be found.":
							seal.reject(ApiError.withMessage(errorMessages.vpnProblem))
						default:
							seal.reject(ApiError.withMessage(error.localizedDescription))
						}
					}
			}
		}
	}

	func exportTracking(tracking: Tracking) -> Promise<[String: Any]> {
		var id: String? = nil
		var bookingTypeString: String! = "abw"
		var activityId: String! = nil
		var taskId: String! = nil

		if let trackingId = tracking.id {
			id = trackingId
		}

		if let types = fetchedResultControllerType.fetchedObjects, let bookingType = types.first(where: { $0.id == tracking.job?.type?.id }) {
			if (bookingType.internal_service) {
				bookingTypeString = "int"
			} else if (bookingType.productive_service) {
				bookingTypeString = "prod"
			}
		}

		if let activity = tracking.activity {
			activityId = activity.id
		}

		if let task = tracking.task {
			taskId = task.id
		}

		let parameters: [String: Any] = [
			"jsonrpc": "2.0",
			"method": "mytime.put_hourbooking",
			"params": [
				"session": sessionId!,
				"hourbooking": [
					"id": id as Any,
					"date": dateFormatterFull.string(from: tracking.date_start! as Date),
					"time_from": dateFormatterTime.string(from: tracking.date_start! as Date),
					"time_until": dateFormatterTime.string(from: tracking.date_end! as Date),
					"job_id": tracking.job?.id as Any,
					"activity_id": activityId as Any,
					"jobtask_id": taskId as Any,
					"text": tracking.comment as Any,
					"booking_type": bookingTypeString as Any
				] as [String: Any]
			] as [String: Any],
			"id": 1
		]

		return fetch(params: parameters)
	}

}

// MARK: - login

extension QuoJob {

	func checkLoginStatus() -> Promise<[String: Any]> {
		let verifyParams: [String: Any] = [
			"jsonrpc": "2.0",
			"method": "session.get_current_user",
			"params": [
				"session": sessionId
			],
			"id": 1
		]

		return fetch(params: verifyParams)
	}

	func loginWithUserData(userName: String, password: String) -> Promise<Void> {
		let parameters: [String: Any] = [
			"jsonrpc": "2.0",
			"method": "session.login",
			"id": "1",
			"params": [
				"user": userName,
				"device_id": "foo",
				"client_type": "MoJobApp",
				"language": "de",
				"password": password.MD5 as Any,
				"min_version": 1,
				"max_version": 6
			]
		]

		return fetch(params: parameters).done { result in
			self.userId = result["user_id"] as? String
			self.sessionId = result["session"] as? String

			//			Crashlytics.sharedInstance().setUserName(userName)
			//			Answers.logLogin(withMethod: "userData", success: true, customAttributes: [:])
		}
	}

	func loginWithKeyChain() -> Promise<Void> {
		keychain = Keychain(service: KEYCHAIN_NAMESPACE)

		guard keychain.allKeys().count > 0 else {
			return Promise { $0.reject(ApiError.withMessage(errorMessages.sessionProblem)) }
		}

		guard
			let name = keychain.allKeys().first,
			let pass = try? keychain.get(name)
		else {
			return Promise { $0.reject(ApiError.withMessage(errorMessages.sessionProblem)) }
		}

		return loginWithUserData(userName: name, password: pass!)
	}

}

// MARK: - fetch Data from QuoJob

extension QuoJob {

	func syncData() -> Promise<Void> {
		lastSync = fetchedResultControllerSync.fetchedObjects?.first

		return when(fulfilled: fetchJobTypes(), fetchActivities())
			.then { (resultTypes, resultActivities) -> Promise<[String: Any]> in
				self.handleJobTypes(with: resultTypes)
				try? self.fetchedResultControllerType.performFetch()

				self.handleActivities(with: resultActivities)
				try? self.fetchedResultControllerActivity.performFetch()

				return self.fetchJobs()
			}.then { resultJobs -> Promise<[String: Any]> in
				self.handleJobs(with: resultJobs)
				try? self.fetchedResultControllerJob.performFetch()

				return self.fetchTasks()
			}.done { resultTasks in
				self.handleTasks(with: resultTasks)
			}
	}

	func fetchJobTypes() -> Promise<[String: Any]> {
		var lastSyncString: String! = nil
		if let lastSyncTime = lastSync?.tasks {
			lastSyncString = dateFormatterFull.string(from: lastSyncTime)
		}

		let parameters: [String: Any] = [
			"jsonrpc": "2.0",
			"method": "job.get_jobtypes",
			"params": [
				"session": sessionId,
				"last_sync": lastSyncString
			],
			"id": 1
		]

		return fetch(params: parameters)
	}

	func fetchJobs() -> Promise<[String: Any]> {
		var lastSyncString: String! = nil
		if let lastSyncTime = lastSync?.jobs {
			lastSyncString = dateFormatterFull.string(from: lastSyncTime)
		}

		let parameters: [String: Any] = [
			"jsonrpc": "2.0",
			"method": "job.get_jobs",
			"params": [
				"session": sessionId,
				"last_sync": lastSyncString
			],
			"id": 1
		]

		return fetch(params: parameters)
	}

	func fetchActivities() -> Promise<[String: Any]> {
		var lastSyncString: String! = nil
		if let lastSyncTime = lastSync?.activities {
			lastSyncString = dateFormatterFull.string(from: lastSyncTime)
		}

		let parameters: [String: Any] = [
			"jsonrpc": "2.0",
			"method": "common.get_activities",
			"params": [
				"session": sessionId,
				"last_sync": lastSyncString
			],
			"id": 1
		]

		return fetch(params: parameters)
	}

	func fetchTasks() -> Promise<[String: Any]> {
		var lastSyncString: String! = nil
		if let lastSyncTime = lastSync?.tasks {
			lastSyncString = dateFormatterFull.string(from: lastSyncTime)
		}

		let parameters: [String: Any] = [
			"jsonrpc": "2.0",
			"method": "job.get_jobtasks",
			"params": [
				"session": sessionId,
				"last_sync": lastSyncString
			],
			"id": 1
		]

		return fetch(params: parameters)
	}

	private func handleJobTypes(with result: [String: Any]) {
		if var typeItems = result["jobtypes"] as? [[String: Any]], let timestamp = result["timestamp"] as? String {
			var types: [Type]?

			if (typeItems.count > 0) {
				types = self.fetchedResultControllerType.fetchedObjects
			}

			typeItems = typeItems.filter({
				if let active = $0["active"] as? Bool {
					return active
				}

				return false
			})

			for item in typeItems {
				let id = item["id"] as! String
				let title = item["name"] as! String
				let active = item["active"] as! Bool
				let internalService = item["internal"] as! Bool
				let productiveService = item["productive"] as! Bool

				if let type = types?.first(where: { $0.id == id }) {
					type.title = title
					type.active = active
					type.internal_service = internalService
					type.productive_service = productiveService
				} else {
					let entity = NSEntityDescription.entity(forEntityName: "Type", in: self.context)
					let type = NSManagedObject(entity: entity!, insertInto: self.context)
					let typeValues: [String: Any] = [
						"id": id,
						"title": title,
						"active": active,
						"internal_service": internalService,
						"productive_service": productiveService
					]
					type.setValuesForKeys(typeValues)
				}
			}

			let newSyncDate = self.dateFormatterFull.date(from: timestamp)

			if (self.lastSync == nil) {
				let entity = NSEntityDescription.entity(forEntityName: "Sync", in: self.context)
				self.lastSync = NSManagedObject(entity: entity!, insertInto: self.context) as? Sync
			}

			self.lastSync?.types = newSyncDate

			do {
				try self.context.save()
			} catch let error {
				print(error)
			}
		}
	}

	private func handleJobs(with result: [String: Any]) {
		if var jobItems = result["jobs"] as? [[String: Any]], let timestamp = result["timestamp"] as? String {
			var jobs: [Job]?

			if (jobItems.count > 0) {
				jobs = fetchedResultControllerJob.fetchedObjects
			}

			var typeIds: [String] = []
			if let types = fetchedResultControllerType.fetchedObjects {
				typeIds = types.map({ $0.id! })
			}

			jobItems = jobItems.filter({
				if let bookable = $0["bookable"] as? Bool {
					return bookable && typeIds.contains($0["job_type_id"] as! String)
				}

				return false
			})

			for item in jobItems {
				let id = item["id"] as! String
				let number = item["number"] as! String
				let title = item["title"] as! String
				let typeId = item["job_type_id"] as! String
				let assigned_user_ids = item["assigned_user_ids"] as! [String]
				let type = fetchedResultControllerType.fetchedObjects?.first(where: { $0.id == typeId })

				if let job = jobs?.first(where: { $0.id == id }) {
					job.assigned = assigned_user_ids.contains(self.userId)
					job.number = number
					job.title = title
					job.type = type
				} else {
					let entity = NSEntityDescription.entity(forEntityName: "Job", in: self.context)
					let job = NSManagedObject(entity: entity!, insertInto: self.context)
					let jobValues: [String: Any] = [
						"id": id,
						"title": title,
						"number": number,
						"assigned": assigned_user_ids.contains(self.userId),
						"type": type!
					]
					job.setValuesForKeys(jobValues)
				}
			}

			let newSyncDate = self.dateFormatterFull.date(from: timestamp)

			if (self.lastSync == nil) {
				let entity = NSEntityDescription.entity(forEntityName: "Sync", in: self.context)
				self.lastSync = NSManagedObject(entity: entity!, insertInto: self.context) as? Sync
			}

			self.lastSync?.jobs = newSyncDate

			do {
				try self.context.save()
			} catch let error {
				print(error)
			}
		}
	}

	private func handleActivities(with result: [String: Any]) {
		if var activityItems = result["activities"] as? [[String: Any]], let timestamp = result["timestamp"] as? String {
			var activities: [Activity]?

			if (activityItems.count > 0) {
				activities = self.fetchedResultControllerActivity.fetchedObjects
			}

			activityItems = activityItems.filter({ $0["active"] as? Bool ?? false })

			for item in activityItems {
				let id = item["id"] as! String
				let title = item["name"] as! String
				let internal_service = item["internal"] as! Bool
				let external_service = item["external_service"] as! Bool
				let nfc = item["nfc"] as! Bool

				if let activity = activities?.first(where: { $0.id == id }) {
					activity.title = title
					activity.internal_service = internal_service
					activity.external_service = external_service
					activity.nfc = nfc
				} else {
					let entity = NSEntityDescription.entity(forEntityName: "Activity", in: self.context)
					let activity = NSManagedObject(entity: entity!, insertInto: self.context)
					let activityValues: [String: Any] = [
						"id": id,
						"title": title,
						"internal_service": internal_service,
						"external_service": external_service,
						"nfc": nfc
					]
					activity.setValuesForKeys(activityValues)
				}
			}

			let newSyncDate = self.dateFormatterFull.date(from: timestamp)

			if (self.lastSync == nil) {
				let entity = NSEntityDescription.entity(forEntityName: "Sync", in: self.context)
				self.lastSync = NSManagedObject(entity: entity!, insertInto: self.context) as? Sync
			}

			self.lastSync?.activities = newSyncDate

			do {
				try self.context.save()
			} catch let error {
				print(error)
			}
		}
	}

	private func handleTasks(with result: [String: Any]) {
		if var taskItems = result["jobtasks"] as? [[String: Any]], let timestamp = result["timestamp"] as? String {
			var tasks: [Task]?

			if (taskItems.count > 0) {
				tasks = self.fetchedResultControllerTask.fetchedObjects
			}

			var jobIds: [String] = []
			if let jobs = fetchedResultControllerJob.fetchedObjects {
				jobIds = jobs.map({ $0.id! })
			}

			taskItems = taskItems.filter({
				if let status = $0["status"] as? String {
					return status == "active" && jobIds.contains($0["job_id"] as! String)
				}

				return false
			})

			for item in taskItems {
				let id = item["id"] as! String
				let title = item["subject"] as! String

				var jobObject: Job? = nil
				if let jobId = item["job_id"] as? String, let job = fetchedResultControllerJob.fetchedObjects?.first(where: { $0.id == jobId }) {
					jobObject = job
				}

				var activityObject: Activity? = nil
				if let activityId = item["activity_id"] as? String, let activity = fetchedResultControllerActivity.fetchedObjects?.first(where: { $0.id == activityId }) {
					activityObject = activity
				}

				var hoursPlaned = Double()
				if let hours_planed = item["hours_planed"] as? NSString {
					hoursPlaned = hours_planed.doubleValue
				} else if let hours_planed = item["hours_planed"] as? Double {
					hoursPlaned = hours_planed
				}

				var hoursBooked = Double()
				if let hours_booked = item["hours_booked"] as? NSString {
					hoursBooked = hours_booked.doubleValue
				} else if let hours_booked = item["hours_booked"] as? Double {
					hoursBooked = hours_booked
				}

				if let task = tasks?.first(where: { $0.id == id }) {
					task.title = title
					task.hours_planed = hoursPlaned
					task.hours_booked = hoursBooked
					task.job = jobObject
					task.activity = activityObject
				} else {
					let entity = NSEntityDescription.entity(forEntityName: "Task", in: self.context)
					let task = NSManagedObject(entity: entity!, insertInto: self.context)
					let taskValues: [String: Any] = [
						"id": id,
						"title": title,
						"hours_planed": hoursPlaned,
						"hours_booked": hoursBooked,
						"job": jobObject as Any,
						"activity": activityObject as Any
					]
					task.setValuesForKeys(taskValues)
				}
			}

			let newSyncDate = self.dateFormatterFull.date(from: timestamp)

			if (self.lastSync == nil) {
				let entity = NSEntityDescription.entity(forEntityName: "Sync", in: self.context)
				self.lastSync = NSManagedObject(entity: entity!, insertInto: self.context) as? Sync
			}

			self.lastSync?.tasks = newSyncDate

			do {
				try self.context.save()
			} catch let error {
				print(error)
			}
		}
	}

}
