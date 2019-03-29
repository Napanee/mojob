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


#if DEVELOPMENT
	let API_URL = "https://mojob-test.moccu/index.php?rpc=1"
#else
	let API_URL = "https://mojob-test.moccu/index.php?rpc=1"
#endif

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

	let dateFormatter = DateFormatter()

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

		dateFormatter.dateFormat = "YYYYMMddHHmmss"
	}

	func checkLoginStatus(success: @escaping () -> Void, failed: @escaping (_ error: String) -> Void, err: @escaping (_ error: String) -> Void) {
		if (sessionId == "") {
			loginWithKeyChain(success: success, failed: failed, err: err)
			return
		}

		let params: [String: String] = [
			"session": sessionId
		]
		let verifyParams: [String: Any] = [
			"jsonrpc": "2.0",
			"method": "session.get_current_user",
			"params": params,
			"id": 1
		]

		Alamofire.request(API_URL, method: .post, parameters: verifyParams, encoding: JSONEncoding.default)
			.responseJSON { response in switch response.result {
			case .success(let JSON):
				let response = JSON as! NSDictionary

				if (response.allKeys.contains(where: { ($0 as! String) == "error" })) {
					let error = (response.object(forKey: "error")! as! NSDictionary)
					let statusCode = error.object(forKey: "code")! as! Int

					/*
					* 2003 No session given
					* 2004 Invalid session
					*/
					switch statusCode {
						case 2003, 2004:
							self.loginWithKeyChain(success: success, failed: failed, err: err)
						default:
							err("Fehlercode: \(statusCode) - Bitte an Martin wenden.")
					}
				} else if (response.allKeys.contains(where: { ($0 as! String) == "result" })) {
					success()
				}
			case .failure(let error):
				let errorMessage = error.localizedDescription

				if ((errorMessage.range(of:"A server with the specified hostname could not be found.")) != nil) {
					err("Du bist nicht per VPN mit dem Moccu-Netzwerk verbunden. Deine Trackings werden nicht an QuoJob übertragen.")
				} else {
					err(errorMessage)
				}
			}
		}
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

	private func loginWithKeyChain(success: @escaping () -> Void, failed: @escaping (_ error: String) -> Void, err: @escaping (_ error: String) -> Void) {
		keychain = Keychain(service: "de.mojobapp-dev.login")

		guard keychain.allKeys().count > 0 else {
			failed("Error 1001: Du bist ausgeloggt. Logge dich bei QuoJob ein, um deine Trackings übertragen zu können.")
			return
		}

		guard
			let name = keychain.allKeys().first,
			let pass = try? keychain.get(name)
		else {
			failed("Error 1002: Du bist ausgeloggt. Logge dich bei QuoJob ein, um deine Trackings übertragen zu können.")
			return
		}

		let parameters: [String: Any] = [
			"jsonrpc": "2.0",
			"method": "session.login",
			"id": "1",
			"params": [
				"user": name,
				"device_id": "foo",
				"client_type": "MoJobApp",
				"language": "de",
				"password": pass!.MD5 as Any,
				"min_version": 1,
				"max_version": 6
			]
		]

		Alamofire.request(API_URL, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
			switch response.result {
				case .success(let JSON):
					let response = JSON as! NSDictionary

					if (response.allKeys.contains(where: { ($0 as! String) == "error" })) {
						let error = (response.object(forKey: "error")! as! NSDictionary)
						let statusCode = (error.object(forKey: "code") as! NSString).intValue

						/*
						* 1000: No right for the requestes action
						*/
						if ([1000].contains(statusCode)) {
							failed("Dein QuoJob-Account ist nicht für die API freigeschaltet. Bitte wende dich an den QuoJob-Verantwortlichen.")
						}
					} else if let result = response.object(forKey: "result") as? NSDictionary {
						self.userId = result.object(forKey: "user_id")! as? String
						self.sessionId = result.object(forKey: "session")! as? String

	//							Crashlytics.sharedInstance().setUserName(name)
	//							Answers.logLogin(withMethod: "keyChain", success: true, customAttributes: [:])

						success()
					}
				case .failure(let error):
					let errorMessage = error.localizedDescription

					if ((errorMessage.range(of:"A server with the specified hostname could not be found.")) != nil) {
						err("Du bist nicht per VPN mit dem Moccu-Netzwerk verbunden. Deine Trackings werden nicht an QuoJob übertragen.")
					} else {
						failed(errorMessage)
					}
			}
		}
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
								seal.reject(ApiError.withMessage("Dein QuoJob-Account ist nicht für die API freigeschaltet. Bitte wende dich an den QuoJob-Verantwortlichen."))
							case 2001: // User NOT found
								seal.reject(ApiError.withMessage("User nicht gefunden"))
							case 2002: // Wrong password
								seal.reject(ApiError.withMessage("Userdaten nicht korrekt"))
							case 2003: // No session given
								seal.reject(ApiError.withMessage(""))
							case 2004: // Invalid session
								seal.reject(ApiError.withMessage(""))
							case 2011: // User account is disabled
								seal.reject(ApiError.withMessage("Dein QuoJob-Account ist gesperrt. Bitte wende dich an den QuoJob-Verantwortlichen."))
							default:
								seal.reject(ApiError.other(statusCode))
							}
						} else if let result = json["result"] as? [String: Any] {
							seal.fulfill(result)
						}

						seal.reject(ApiError.withMessage("Unbekannter Fehler. Bitte wende dich an Martin."))
					case .failure(let error):
						seal.reject(error)
					}
			}
		}
	}

	func fetchJobTypes() -> Promise<[String: Any]> {
		var lastSyncString: String! = nil
		if let lastSyncTime = lastSync?.tasks {
			lastSyncString = dateFormatter.string(from: lastSyncTime)
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
			lastSyncString = dateFormatter.string(from: lastSyncTime)
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
			lastSyncString = dateFormatter.string(from: lastSyncTime)
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
			lastSyncString = dateFormatter.string(from: lastSyncTime)
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

			let newSyncDate = self.dateFormatter.date(from: timestamp)

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

			let newSyncDate = self.dateFormatter.date(from: timestamp)

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

			activityItems = activityItems.filter({
				if let active = $0["active"] as? Bool {
					return active
				}

				return false
			})

			for item in activityItems {
				let id = item["id"] as! String
				let title = item["name"] as! String
				let internal_service = item["internal"] as! Bool
				let external_service = item["external_service"] as! Bool

				if let activity = activities?.first(where: { $0.id == id }) {
					activity.title = title
					activity.internal_service = internal_service
					activity.external_service = external_service
				} else {
					let entity = NSEntityDescription.entity(forEntityName: "Activity", in: self.context)
					let activity = NSManagedObject(entity: entity!, insertInto: self.context)
					let activityValues: [String: Any] = [
						"id": id,
						"title": title,
						"internal_service": internal_service,
						"external_service": external_service
					]
					activity.setValuesForKeys(activityValues)
				}
			}

			let newSyncDate = self.dateFormatter.date(from: timestamp)

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

			let newSyncDate = self.dateFormatter.date(from: timestamp)

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
