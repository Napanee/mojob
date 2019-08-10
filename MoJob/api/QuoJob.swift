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


class QuoJob: NSObject {

	public typealias Method = String

	static let shared = QuoJob()

	let utilityQueue = DispatchQueue.global(qos: .utility)
	let dateFormatterFull = DateFormatter()
	let dateFormatterTime = DateFormatter()
	var defaultParams: [String: Any] {
		get {
			return ["session": sessionId!]
		}
	}

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
	var sessionId: String! = ""

	let context = CoreDataHelper.shared.persistentContainer.viewContext
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

	var _fetchedResultsControllerTracking: NSFetchedResultsController<Tracking>? = nil
	var fetchedResultControllerTracking: NSFetchedResultsController<Tracking> {
		if (_fetchedResultsControllerTracking != nil) {
			return _fetchedResultsControllerTracking!
		}

		let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "id", ascending: false)
		]

		let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsControllerTracking = resultsController

		do {
			try _fetchedResultsControllerTracking!.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror)")
		}

		return _fetchedResultsControllerTracking!
	}

	private override init() {
		super.init()

		NSUserNotificationCenter.default.delegate = self

		lastSync = fetchedResultControllerSync.fetchedObjects?.first

		dateFormatterFull.dateFormat = "YYYYMMddHHmmss"
		dateFormatterTime.dateFormat = "HHmm"
	}

	func fetch(as method: QuoJob.Method, with params: [String: Any]) -> Promise<[String: Any]> {
		let parameters: [String: Any] = [
			"jsonrpc": "2.0",
			"method": method,
			"params": params,
			"id": 1
		]

		return Promise { seal in
			Alamofire.request(API_URL, method: .post, parameters: parameters, encoding: JSONEncoding.default)
				.responseJSON(queue: utilityQueue) { response in
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
						case "The Internet connection appears to be offline.":
							seal.reject(ApiError.withMessage(errorMessages.offline))
						default:
							seal.reject(ApiError.withMessage(error.localizedDescription))
						}
					}
			}
		}
	}

	func exportTracking(tracking: Tracking) -> Promise<Void> {
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

		return Promise { seal in
			login().done({ _ in
				var params = self.defaultParams
				params["hourbooking"] = [
					"id": id,
					"date": self.dateFormatterFull.string(from: tracking.date_start! as Date),
					"time_from": self.dateFormatterTime.string(from: tracking.date_start! as Date),
					"time_until": self.dateFormatterTime.string(from: tracking.date_end! as Date),
					"job_id": tracking.job?.id,
					"activity_id": activityId,
					"jobtask_id": taskId,
					"text": tracking.comment,
					"booking_type": bookingTypeString
				]

				self.fetch(as: .myTime_putHourbooking, with: params).done { result in
					if let hourbooking = result["hourbooking"] as? [String: Any], let id = hourbooking["id"] as? String {
						tracking.update(with: ["id": id, "exported": SyncStatus.success.rawValue]).done({ _ in
							seal.fulfill_()
						}).catch({ error in
							seal.reject(error)
						})
					}
				}.catch({ error in
					seal.reject(error)
				})
			}).catch({ error in
				self.loginWithKeyChain().done({ _ in
					var params = self.defaultParams
					params["hourbooking"] = [
						"id": id,
						"date": self.dateFormatterFull.string(from: tracking.date_start! as Date),
						"time_from": self.dateFormatterTime.string(from: tracking.date_start! as Date),
						"time_until": self.dateFormatterTime.string(from: tracking.date_end! as Date),
						"job_id": tracking.job?.id,
						"activity_id": activityId,
						"jobtask_id": taskId,
						"text": tracking.comment,
						"booking_type": bookingTypeString
					]

					self.fetch(as: .myTime_putHourbooking, with: params).done { result in
						if let hourbooking = result["hourbooking"] as? [String: Any], let id = hourbooking["id"] as? String {
							tracking.update(with: ["id": id, "exported": SyncStatus.success.rawValue]).done({ _ in
								seal.fulfill_()
							}).catch({ error in
								seal.reject(error)
							})
						}
					}.catch({ error in
						seal.reject(error)
					})
				}).catch({ error in
				})
			})
		}
	}

	func deleteTracking(tracking: Tracking) -> Promise<[String: Any]> {
		return login().then({ _ -> Promise<[String: Any]> in
			var params = self.defaultParams
			params["hourbooking_id"] = tracking.id

			return self.fetch(as: .myTime_deleteHourbooking, with: params)
		})
	}

}

// MARK: - login

extension QuoJob {

	func isConnectionPossible() -> Promise<Bool> {
		return Promise { seal in
			return fetch(as: .session_isConnectionPossible, with: [:]).done({ _ in
				seal.fulfill(true)
			}).catch({ error in
				seal.reject(error)
			})
		}
	}

	func login() -> Promise<Bool> {
		print("try to login")
		return Promise { seal in
			return self.isLoggedIn().done({ _ in
				print("already logged in")
				seal.fulfill(true)
			}).catch({ _ in
				print("not logged in")
				self.loginWithKeyChain().done({ _ in
					print("logged in with keychain")
					seal.fulfill(true)
				}).catch({ error in
					print("error during login")
					seal.reject(error)
				})
			})
		}
	}

	func isLoggedIn() -> Promise<[String: Any]> {
		let params = defaultParams
		return fetch(as: .session_getCurrentUser, with: params)
	}

	func loginWithUserData(userName: String, password: String) -> Promise<Void> {
		let params = [
			"user": userName,
			"device_id": "foo",
			"client_type": "MoJobApp",
			"language": "de",
			"password": password.MD5 as Any,
			"min_version": 1,
			"max_version": 6
		]

		return fetch(as: .session_login, with: params).done { result in
			print("logged in with userdata from keychain")
			self.userId = result["user_id"] as? String
			self.sessionId = result["session"] as? String

			//			Crashlytics.sharedInstance().setUserName(userName)
			//			Answers.logLogin(withMethod: "userData", success: true, customAttributes: [:])
		}
	}

	func loginWithKeyChain() -> Promise<Void> {
		print("try to login with keychain")
		keychain = Keychain(service: KEYCHAIN_NAMESPACE)
		let keys = keychain.allKeys()

		if keys.count > 0, let name = keys.first, let pass = try? keychain.get(name) {
			print("keychain data found -> login with userdata from keychain")
			return Promise { seal in
				loginWithUserData(userName: name, password: pass!).done({
					seal.fulfill_()
				}).catch({ error in
					self.keychain[name] = nil
					seal.reject(error)
				})
			}
		}

		print("no keychain data")
		return Promise { $0.reject(ApiError.withMessage(errorMessages.sessionProblem)) }
	}

}

// MARK: - fetch Data from QuoJob

extension QuoJob {

	func syncData() -> Promise<Void> {
		lastSync = fetchedResultControllerSync.fetchedObjects?.first
		var results: [[String: Any]] = []

		return login().done { result -> Void in
			return when(fulfilled: self.fetchJobTypes(), self.fetchActivities())
				.then { (resultTypes, resultActivities) -> Promise<[String: Any]> in
					self.handleJobTypes(with: resultTypes)
					try? self.fetchedResultControllerType.performFetch()

					if let newActivities = (resultActivities["activities"] as? [[String: Any]])?
						.filter({ $0["active"] as? Bool ?? false }),
						newActivities.count > 0
					{
						results.append(["type": "activities", "order": 2, "text": "\(String(newActivities.count)) Tätigkeiten"])
					}
					self.handleActivities(with: resultActivities)
					try? self.fetchedResultControllerActivity.performFetch()

					return self.fetchJobs()
				}.then { resultJobs -> Promise<[String: Any]> in
					if
						let newJobs = (resultJobs["jobs"] as? [[String: Any]])?
							.filter({
								(($0["bookable"] as? Bool) ?? false) && ($0["assigned_user_ids"] as! [String]).contains(self.userId)
							}),
						newJobs.count > 0
					{
						results.append(["type": "jobs", "order": 1, "text": "\(String(newJobs.count)) Jobs"])
					}
					self.handleJobs(with: resultJobs)
					try? self.fetchedResultControllerJob.performFetch()

					return self.fetchTasks()
				}.done { resultTasks in
					if
						let jobsAll = self.jobs?.filter({ $0.assigned }).map({ $0.id }),
						let tasks = (resultTasks["jobtasks"] as? [[String: Any]])?.filter({ jobsAll.contains($0["job_id"] as? String) }),
						tasks.count > 0
					{
						results.append(["type": "tasks", "order": 3, "text": "\(String(tasks.count)) Aufgaben"])
					}
					self.handleTasks(with: resultTasks)
				}.ensure {
					var title: String = ""
					var text: String = ""

					if (results.count == 0) {
						title = "Daten aktuell."
						text = "Du kannst loslegen ;)"
					} else {
						title = "Daten erfolgreich synchronisiert."
						text = "Es wurden "

						text += results.sorted(by: { ($0["order"] as! Int) < ($1["order"] as! Int) }).map({ type in
							return type["text"] as! String
						}).joined(separator: ", ")

						text += " importiert oder aktualisiert.\nFröhlichen Arbeitstag ;)"
					}

					GlobalNotification.shared.deliverNotification(withTitle: title, andInformationtext: text)
				}.catch({ error in
					print("SyncError: \(error)")
				})
		}
	}

	func syncTrackings() -> Promise<Void> {
		fetchedResultControllerSync.fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "trackings", ascending: false)
		]
		try? fetchedResultControllerSync.performFetch()

		lastSync = fetchedResultControllerSync.fetchedObjects?.first
		var results: [[String: Any]] = []

		return fetchTrackingChanges()
			.then { resultChanges -> Promise<[String: Any]> in
				guard let result = self.handleTrackingChanges(with: resultChanges), result.count > 0 else {
					return Promise { $0.reject(AFError.responseValidationFailed(reason: .dataFileNil)) }
				}

				return self.fetchTrackings(with: result)
			}.done { resultTrackings in
				if
					let trackingsAll = (resultTrackings["hourbookings"] as? [[String: Any]])?.map({ $0["id"] as! String }),
					let trackingsEdited = self.fetchedResultControllerTracking.fetchedObjects?.filter({ trackingsAll.contains($0.id!) }),
					trackingsEdited.count > 0
				{
					results.append(["type": "trackings_new", "order": 1, "text": "\(String(trackingsAll.count - trackingsEdited.count)) Trackings hinzugefügt"])
					results.append(["type": "trackings_edit", "order": 2, "text": "\(String(trackingsEdited.count)) Trackings aktualisiert"])
				}

				self.handleTrackings(with: resultTrackings)
			}.ensure {
				var title: String = ""
				var text: String = ""

				if (results.count == 0) {
					title = "Trackings aktuell."
				} else {
					title = "Trackings erfolgreich synchronisiert."
					text = "Es wurden "

					text += results.sorted(by: { ($0["order"] as! Int) < ($1["order"] as! Int) }).map({ type in
						return type["text"] as! String
					}).joined(separator: " und ")

					text += "\nFröhlichen Arbeitstag ;)"
				}

				GlobalNotification.shared.deliverNotification(withTitle: title, andInformationtext: text)
			}
	}

	func fetchJobTypes() -> Promise<[String: Any]> {
		var lastSyncString: String! = nil
		if let lastSyncTime = lastSync?.tasks {
			lastSyncString = dateFormatterFull.string(from: lastSyncTime)
		}

		var params = defaultParams
		params["last_sync"] = lastSyncString

		return fetch(as: .job_getJobtypes, with: params)
	}

	func fetchJobs() -> Promise<[String: Any]> {
		var lastSyncString: String! = nil
		if let lastSyncTime = lastSync?.jobs {
			lastSyncString = dateFormatterFull.string(from: lastSyncTime)
		}

		var params = defaultParams
		params["last_sync"] = lastSyncString

		return fetch(as: .job_getJobs, with: params)
	}

	func fetchActivities() -> Promise<[String: Any]> {
		var lastSyncString: String! = nil
		if let lastSyncTime = lastSync?.activities {
			lastSyncString = dateFormatterFull.string(from: lastSyncTime)
		}

		var params = defaultParams
		params["last_sync"] = lastSyncString

		return fetch(as: .common_getActivities, with: params)
	}

	func fetchTasks() -> Promise<[String: Any]> {
		var lastSyncString: String! = nil
		if let lastSyncTime = lastSync?.tasks {
			lastSyncString = dateFormatterFull.string(from: lastSyncTime)
		}

		var params = defaultParams
		params["last_sync"] = lastSyncString

		return fetch(as: .job_getJobtasks, with: params)
	}

	func fetchTrackingChanges() -> Promise<[String: Any]> {
		var lastSyncString: String! = nil
		if let lastSyncTime = lastSync?.trackings {
			lastSyncString = dateFormatterFull.string(from: lastSyncTime)
		}

		var params = defaultParams
		params["last_sync"] = lastSyncString

		return fetch(as: .myTime_getHourbookingChanges, with: params)
	}

	func fetchTrackings(with ids: [String]) -> Promise<[String: Any]> {
		var params = defaultParams
		params["hourbookings"] = ids
		params["filter"] = [
			"user_id": userId
		]

		return fetch(as: .myTime_getHourbookings, with: params)
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
		if let jobItems = result["jobs"] as? [[String: Any]], let timestamp = result["timestamp"] as? String {
			var jobs: [Job]?

			if (jobItems.count > 0) {
				jobs = fetchedResultControllerJob.fetchedObjects
			}

			// not active, because we want ALL jobs for the history
//			var typeIds: [String] = []
//			if let types = fetchedResultControllerType.fetchedObjects {
//				typeIds = types.map({ $0.id! })
//			}
//
//			jobItems = jobItems.filter({
//				if let bookable = $0["bookable"] as? Bool {
//					return bookable && typeIds.contains($0["job_type_id"] as! String)
//				}
//
//				return false
//			})

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

			// not active, because we want ALL tasks for the history
//			taskItems = taskItems.filter({
//				if let status = $0["status"] as? String {
//					return status == "active" && jobIds.contains($0["job_id"] as! String)
//				}
//
//				return false
//			})

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

	private func handleTrackingChanges(with result: [String: Any]) -> [String]? {
		guard
			let new = result["new"] as? [String],
			let changed = result["changed"] as? [String],
			let deleted = result["deleted"] as? [String],
			let timestamp = result["timestamp"] as? String
		else {
			return nil
		}

		if (deleted.count > 0) {
			let trackings = self.fetchedResultControllerTracking.fetchedObjects
			for deletedId in deleted {
				if let tracking = trackings?.first(where: { $0.id == deletedId }) {
					self.context.delete(tracking)
				}
			}

			let newSyncDate = self.dateFormatterFull.date(from: timestamp)

			if (self.lastSync == nil) {
				let entity = NSEntityDescription.entity(forEntityName: "Sync", in: self.context)
				self.lastSync = NSManagedObject(entity: entity!, insertInto: self.context) as? Sync
			}

			self.lastSync?.trackings = newSyncDate

			do {
				try self.context.save()
			} catch let error {
				print(error)
			}
		}

		return new + changed
	}

	private func handleTrackings(with result: [String: Any]) {
		if let trackingItems = result["hourbookings"] as? [[String: Any]], let timestamp = result["timestamp"] as? String {
			guard (trackingItems.count > 0) else { return }

			let trackings = fetchedResultControllerTracking.fetchedObjects
			let jobs = fetchedResultControllerJob.fetchedObjects
			let tasks = fetchedResultControllerTask.fetchedObjects
			let activities = fetchedResultControllerActivity.fetchedObjects

			for item in trackingItems {
				let id = item["id"] as! String
				let quantity = item["quantity"] as! Double
				var date = item["date"] as! String
				let timeFrom = item["time_from"] as! String
				let timeUntil = item["time_until"] as! String
				let text = item["text"] as! String

				if let timeInterval = dateFormatterFull.date(from: date)?.timeIntervalSince1970, timeInterval < 0 {
					date = item["date_created"] as! String
				}

				var jobObject: Job? = nil
				if let jobId = item["job_id"] as? String, let job = jobs?.first(where: { $0.id == jobId }) {
					jobObject = job
				}

				var activityObject: Activity? = nil
				if let activityId = item["activity_id"] as? String, let activity = activities?.first(where: { $0.id == activityId }) {
					activityObject = activity
				}

				var taskObject: Task? = nil
				if let taskId = item["jobtask_id"] as? String, let task = tasks?.first(where: { $0.id == taskId }) {
					taskObject = task
				}

				var dateStart: Date!
				var dateEnd: Date!
				if (timeUntil == "" || timeFrom == "") {
					dateStart = dateFormatterFull.date(from: date)
					dateEnd = Calendar.current.date(byAdding: .minute, value: Int(round(quantity * 60)), to: dateStart!)
				} else {
					let trackingDate = dateFormatterFull.date(from: date)
					let timeFromDate = Calendar.current.dateComponents([.hour, .minute], from: dateFormatterTime.date(from: timeFrom)!)
					let timeUntilDate = Calendar.current.dateComponents([.hour, .minute], from: dateFormatterTime.date(from: timeUntil)!)

					dateStart = Calendar.current.date(bySettingHour: timeFromDate.hour!, minute: timeFromDate.minute!, second: 0, of: trackingDate!)
					dateEnd = Calendar.current.date(bySettingHour: timeUntilDate.hour!, minute: timeFromDate.minute!, second: 0, of: trackingDate!)
				}

				if let tracking = trackings?.first(where: { $0.id == id }) {
					tracking.job = jobObject
					tracking.task = taskObject
					tracking.activity = activityObject
					tracking.date_start = dateStart
					tracking.date_end = dateEnd
					tracking.comment = text
					tracking.exported = SyncStatus.success.rawValue
				} else {
					let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: self.context)
					let tracking = NSManagedObject(entity: entity!, insertInto: self.context)
					let trackingValues: [String: Any?] = [
						"id": id,
						"job": jobObject,
						"task": taskObject,
						"activity": activityObject,
						"date_start": dateStart,
						"date_end": dateEnd,
						"comment": text,
						"exported": SyncStatus.success.rawValue
					]

					tracking.setValuesForKeys(trackingValues as [String: Any])
				}
			}

			do {
				try self.context.save()
			} catch let error {
				print(error)
			}
		}
	}

}


extension QuoJob: NSUserNotificationCenterDelegate {

	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}

}
