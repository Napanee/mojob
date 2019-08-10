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
			var result: [Job]?
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
				result = try context.fetch(fetchRequest)
			} catch let error {
				print(error)
			}

			return result
		}
	}

	var activities: [Activity]? {
		get {
			var result: [Activity]?
			let fetchRequest: NSFetchRequest<Activity> = Activity.fetchRequest()
			fetchRequest.sortDescriptors = [
				NSSortDescriptor(key: "title", ascending: false)
			]

			do {
				result = try context.fetch(fetchRequest)
			} catch let error {
				print(error)
			}

			return result
		}
	}

	var tasks: [Task]? {
		get {
			var result: [Task]?
			let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
			fetchRequest.sortDescriptors = [
				NSSortDescriptor(key: "title", ascending: false)
			]

			do {
				result = try context.fetch(fetchRequest)
			} catch let error {
				print(error)
			}

			return result
		}
	}

	var types: [Type]? {
		get {
			var result: [Type]?
			let fetchRequest: NSFetchRequest<Type> = Type.fetchRequest()
			fetchRequest.sortDescriptors = [
				NSSortDescriptor(key: "title", ascending: false)
			]

			do {
				result = try context.fetch(fetchRequest)
			} catch let error {
				print(error)
			}

			return result
		}
	}

	var trackings: [Tracking]? {
		get {
			var result: [Tracking]?
			let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()
			fetchRequest.sortDescriptors = [
				NSSortDescriptor(key: "id", ascending: false)
			]

			do {
				result = try context.fetch(fetchRequest)
			} catch let error {
				print(error)
			}

			return result
		}
	}

	var keychain: Keychain!
	var userId: String!
	var sessionId: String! = ""

	let context = CoreDataHelper.context
	let taskContext = CoreDataHelper.backgroundContext

	private override init() {
		super.init()

		NSUserNotificationCenter.default.delegate = self

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

		if let types = types, let bookingType = types.first(where: { $0.id == tracking.job?.type?.id }) {
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
		return Promise { seal in
			return self.isLoggedIn().done({ _ in
				seal.fulfill(true)
			}).catch({ _ in
				self.loginWithKeyChain().done({ _ in
					seal.fulfill(true)
				}).catch({ error in
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
			self.userId = result["user_id"] as? String
			self.sessionId = result["session"] as? String

			//			Crashlytics.sharedInstance().setUserName(userName)
			//			Answers.logLogin(withMethod: "userData", success: true, customAttributes: [:])
		}
	}

	func loginWithKeyChain() -> Promise<Void> {
		keychain = Keychain(service: KEYCHAIN_NAMESPACE)
		let keys = keychain.allKeys()

		if keys.count > 0, let name = keys.first, let pass = try? keychain.get(name) {
			return Promise { seal in
				loginWithUserData(userName: name, password: pass!).done({
					seal.fulfill_()
				}).catch({ error in
					self.keychain[name] = nil
					seal.reject(error)
				})
			}
		}

		return Promise { $0.reject(ApiError.withMessage(errorMessages.sessionProblem)) }
	}

}

// MARK: - fetch Data from QuoJob

extension QuoJob {

	func syncData() -> Promise<Void> {
		var results: [[String: Any]] = []

		return login().done { result -> Void in
			return when(fulfilled: self.fetchJobTypes(), self.fetchActivities())
				.then { (resultTypes, resultActivities) -> Promise<Void> in
					if let newActivities = (resultActivities["activities"] as? [[String: Any]])?
						.filter({ $0["active"] as? Bool ?? false }),
						newActivities.count > 0
					{
						results.append(["type": "activities", "order": 2, "text": "\(String(newActivities.count)) Tätigkeiten"])
					}

					return when(fulfilled: self.handleJobTypes(with: resultTypes), self.handleActivities(with: resultActivities))
				}.then { _ -> Promise<[String: Any]> in
					return self.fetchJobs()
				}.then { resultJobs -> Promise<Void> in
					if
						let newJobs = (resultJobs["jobs"] as? [[String: Any]])?
							.filter({
								(($0["bookable"] as? Bool) ?? false) && ($0["assigned_user_ids"] as! [String]).contains(self.userId)
							}),
						newJobs.count > 0
					{
						results.append(["type": "jobs", "order": 1, "text": "\(String(newJobs.count)) Jobs"])
					}

					return self.handleJobs(with: resultJobs)
				}.then { _ -> Promise<[String: Any]> in
					return self.fetchTasks()
				}.then { resultTasks -> Promise<Void> in
					if
						let jobsAll = self.jobs?.filter({ $0.assigned }).map({ $0.id }),
						let tasks = (resultTasks["jobtasks"] as? [[String: Any]])?.filter({ jobsAll.contains($0["job_id"] as? String) }),
						tasks.count > 0
					{
						results.append(["type": "tasks", "order": 3, "text": "\(String(tasks.count)) Aufgaben"])
					}

					return self.handleTasks(with: resultTasks)
				}.then { _ -> Promise<[String: Any]> in
					return self.fetchTrackingChanges()
				}.then { resultChanges -> Promise<[String]> in
					return self.handleTrackingChanges(with: resultChanges)
				}.then { result -> Promise<[String: Any]> in
					return self.fetchTrackings(with: result)
				}.then { resultTrackings -> Promise<Void> in
					if
						let trackingsAll = (resultTrackings["hourbookings"] as? [[String: Any]])?.map({ $0["id"] as! String }),
						let trackingsEdited = self.trackings?.filter({
							guard let id = $0.id else { return false }
							return trackingsAll.contains(id)
						}),
						trackingsEdited.count > 0
					{
						results.append(["type": "trackings_new", "order": 1, "text": "\(String(trackingsAll.count - trackingsEdited.count)) Trackings hinzugefügt"])
						results.append(["type": "trackings_edit", "order": 2, "text": "\(String(trackingsEdited.count)) Trackings aktualisiert"])
					}

					return self.handleTrackings(with: resultTrackings)
				}.done { _ in
					do {
						try self.context.save()
					} catch let error {
						print(error)
					}

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

	func fetchJobTypes() -> Promise<[String: Any]> {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Type")
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "sync", ascending: false)
		]

		var params = defaultParams

		if let types = try? taskContext.fetch(fetchRequest) as? [Type], let type = types?.first, let lastSync = type.sync {
			params["last_sync"] = dateFormatterFull.string(from: lastSync)
		}

		return fetch(as: .job_getJobtypes, with: params)
	}

	func fetchJobs() -> Promise<[String: Any]> {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Job")
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "sync", ascending: false)
		]

		var params = defaultParams

		if let jobs = try? taskContext.fetch(fetchRequest) as? [Job], let job = jobs?.first, let lastSync = job.sync {
			params["last_sync"] = dateFormatterFull.string(from: lastSync)
		}

		return fetch(as: .job_getJobs, with: params)
	}

	func fetchActivities() -> Promise<[String: Any]> {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "sync", ascending: false)
		]

		var params = defaultParams

		if let activities = try? taskContext.fetch(fetchRequest) as? [Activity], let activity = activities?.first, let lastSync = activity.sync {
			params["last_sync"] = dateFormatterFull.string(from: lastSync)
		}

		return fetch(as: .common_getActivities, with: params)
	}

	func fetchTasks() -> Promise<[String: Any]> {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Task")
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "sync", ascending: false)
		]

		var params = defaultParams

		if let tasks = try? taskContext.fetch(fetchRequest) as? [Task], let task = tasks?.first, let lastSync = task.sync {
			params["last_sync"] = dateFormatterFull.string(from: lastSync)
		}

		return fetch(as: .job_getJobtasks, with: params)
	}

	func fetchTrackingChanges() -> Promise<[String: Any]> {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tracking")
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "sync", ascending: false)
		]

		var params = defaultParams

		if let trackings = try? taskContext.fetch(fetchRequest) as? [Tracking], let tracking = trackings?.first, let lastSync = tracking.sync {
			params["last_sync"] = dateFormatterFull.string(from: lastSync)
		}

		return fetch(as: .myTime_getHourbookingChanges, with: params)
	}

	func fetchTrackings(with ids: [String]) -> Promise<[String: Any]> {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Tracking")
		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "sync", ascending: false)
		]

		var params = defaultParams
		params["hourbookings"] = ids
		params["filter"] = [
			"user_id": userId
		]

		if let trackings = try? taskContext.fetch(fetchRequest) as? [Tracking], let tracking = trackings?.first, let lastSync = tracking.sync {
			params["last_sync"] = dateFormatterFull.string(from: lastSync)
		}

		return fetch(as: .myTime_getHourbookings, with: params)
	}

	private func handleJobTypes(with result: [String: Any]) -> Promise<Void> {
		return Promise { seal in
			guard var typeItems = result["jobtypes"] as? [[String: Any]], let timestamp = result["timestamp"] as? String, typeItems.count > 0 else {
				seal.fulfill_()
				return
			}

			let syncDate = self.dateFormatterFull.date(from: timestamp)

			typeItems = typeItems.filter({
				if let active = $0["active"] as? Bool {
					return active
				}

				return false
			})

			taskContext.perform {
				for item in typeItems {
					let id = item["id"] as! String
					let title = item["name"] as! String
					let active = item["active"] as! Bool
					let internalService = item["internal"] as! Bool
					let productiveService = item["productive"] as! Bool

					if let type = self.types?.first(where: { $0.id == id }) {
						type.title = title
						type.active = active
						type.internal_service = internalService
						type.productive_service = productiveService
						type.sync = syncDate
					} else {
						let entity = NSEntityDescription.entity(forEntityName: "Type", in: self.taskContext)
						let type = NSManagedObject(entity: entity!, insertInto: self.taskContext)
						let typeValues: [String: Any] = [
							"id": id,
							"title": title,
							"active": active,
							"internal_service": internalService,
							"productive_service": productiveService,
							"sync": syncDate as Any
						]
						type.setValuesForKeys(typeValues)
					}
				}

				do {
					try self.taskContext.save()
					seal.fulfill_()
				} catch let error {
					seal.reject(error)
				}
			}
		}
	}

	private func handleJobs(with result: [String: Any]) -> Promise<Void> {
		return Promise { seal in
			guard let jobItems = result["jobs"] as? [[String: Any]], let timestamp = result["timestamp"] as? String, jobItems.count > 0 else {
				seal.fulfill_()
				return
			}

			let syncDate = self.dateFormatterFull.date(from: timestamp)

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

			taskContext.perform {
				for item in jobItems {
					let id = item["id"] as! String
					let number = item["number"] as! String
					let bookable = item["bookable"] as! Bool
					let title = item["title"] as! String
					let typeId = item["job_type_id"] as! String
					let assigned_user_ids = item["assigned_user_ids"] as! [String]

					if let job = self.jobs?.first(where: { $0.id == id }) {
						let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Type")
						fetchRequest.predicate = NSPredicate(format: "id == %@", argumentArray: [typeId])
						let type = (try? self.context.fetch(fetchRequest) as! [Type])?.first

						job.assigned = assigned_user_ids.contains(self.userId)
						job.bookable = bookable
						job.number = number
						job.title = title
						job.type = type
						job.sync = syncDate
					} else {
						let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Type")
						fetchRequest.predicate = NSPredicate(format: "id == %@", argumentArray: [typeId])
						let type = (try? self.taskContext.fetch(fetchRequest) as! [Type])?.first

						let entity = NSEntityDescription.entity(forEntityName: "Job", in: self.taskContext)
						let job = NSManagedObject(entity: entity!, insertInto: self.taskContext)
						let jobValues: [String: Any] = [
							"id": id,
							"title": title,
							"number": number,
							"assigned": assigned_user_ids.contains(self.userId),
							"bookable": bookable,
							"type": type!,
							"sync": syncDate as Any
						]
						job.setValuesForKeys(jobValues)
					}
				}

				do {
					try self.taskContext.save()
					seal.fulfill_()
				} catch let error {
					seal.reject(error)
				}
			}
		}
	}

	private func handleActivities(with result: [String: Any]) -> Promise<Void> {
		return Promise { seal in
			guard var activityItems = result["activities"] as? [[String: Any]], let timestamp = result["timestamp"] as? String, activityItems.count > 0 else {
				seal.fulfill_()
				return
			}

			let syncDate = self.dateFormatterFull.date(from: timestamp)

			activityItems = activityItems.filter({ $0["active"] as? Bool ?? false })

			self.taskContext.perform {
				for item in activityItems {
					let id = item["id"] as! String
					let title = item["name"] as! String
					let internal_service = item["internal"] as! Bool
					let external_service = item["external_service"] as! Bool
					let nfc = item["nfc"] as! Bool

					if let activity = self.activities?.first(where: { $0.id == id }) {
						activity.title = title
						activity.internal_service = internal_service
						activity.external_service = external_service
						activity.nfc = nfc
						activity.sync = syncDate
					} else {
						let entity = NSEntityDescription.entity(forEntityName: "Activity", in: self.taskContext)
						let activity = NSManagedObject(entity: entity!, insertInto: self.taskContext)
						let activityValues: [String: Any] = [
							"id": id,
							"title": title,
							"internal_service": internal_service,
							"external_service": external_service,
							"nfc": nfc,
							"sync": syncDate as Any
						]
						activity.setValuesForKeys(activityValues)
					}
				}

				do {
					try self.taskContext.save()
					seal.fulfill_()
				} catch let error {
					seal.reject(error)
				}
			}
		}
	}

	private func handleTasks(with result: [String: Any]) -> Promise<Void> {
		return Promise { seal in
			guard let taskItems = result["jobtasks"] as? [[String: Any]], let timestamp = result["timestamp"] as? String, taskItems.count > 0 else {
				seal.fulfill_()
				return
			}

			let syncDate = self.dateFormatterFull.date(from: timestamp)

			// not active, because we want ALL tasks for the history
//			var jobIds: [String] = []
//			if let jobs = fetchedResultControllerJob.fetchedObjects {
//				jobIds = jobs.map({ $0.id! })
//			}
//
//			taskItems = taskItems.filter({
//				if let status = $0["status"] as? String {
//					return status == "active" && jobIds.contains($0["job_id"] as! String)
//				}
//
//				return false
//			})

			let fetchRequestJob = NSFetchRequest<NSFetchRequestResult>(entityName: "Job")
			let jobs = try? taskContext.fetch(fetchRequestJob) as! [Job]

			let fetchRequestActivity = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
			let activities = try? taskContext.fetch(fetchRequestActivity) as! [Activity]

			self.taskContext.perform {
				for item in taskItems {
					let id = item["id"] as! String
					let title = item["subject"] as! String

					var jobObject: Job? = nil
					if let jobId = item["job_id"] as? String, let job = jobs?.first(where: { $0.id == jobId }) {
						jobObject = job
					}

					var activityObject: Activity? = nil
					if let activityId = item["activity_id"] as? String, let activity = activities?.first(where: { $0.id == activityId }) {
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

					if let task = self.tasks?.first(where: { $0.id == id }) {
						task.title = title
						task.hours_planed = hoursPlaned
						task.hours_booked = hoursBooked
						task.job = jobObject
						task.activity = activityObject
						task.sync = syncDate
					} else {
						let entity = NSEntityDescription.entity(forEntityName: "Task", in: self.taskContext)
						let task = NSManagedObject(entity: entity!, insertInto: self.taskContext)
						let taskValues: [String: Any] = [
							"id": id,
							"title": title,
							"hours_planed": hoursPlaned,
							"hours_booked": hoursBooked,
							"job": jobObject as Any,
							"activity": activityObject as Any,
							"sync": syncDate as Any
						]
						task.setValuesForKeys(taskValues)
					}
				}

				do {
					try self.taskContext.save()
					seal.fulfill_()
				} catch let error {
					seal.reject(error)
				}
			}
		}
	}

	private func handleTrackingChanges(with result: [String: Any]) -> Promise<[String]> {
		return Promise { seal in
			guard let new = result["new"] as? [String], let changed = result["changed"] as? [String], let deleted = result["deleted"] as? [String] else {
				seal.fulfill([])
				return
			}

			guard deleted.count > 0 else {
				seal.fulfill(new + changed)
				return
			}

			let trackingsBackground = (try? taskContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Tracking")) as! [Tracking])

			self.taskContext.perform {
				for deletedId in deleted {
					if let tracking = trackingsBackground?.first(where: { $0.id == deletedId }) {
						self.taskContext.delete(tracking)
					}
				}

				do {
					try self.taskContext.save()
					seal.fulfill(new + changed)
				} catch let error {
					seal.reject(error)
				}
			}
		}
	}

	private func handleTrackings(with result: [String: Any]) -> Promise<Void> {
		return Promise { seal in
			guard let trackingItems = result["hourbookings"] as? [[String: Any]], let timestamp = result["timestamp"] as? String, trackingItems.count > 0 else {
				seal.fulfill_()
				return
			}

			let jobsBackground = (try? taskContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Job")) as! [Job])
			let tasksBackground = (try? taskContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Task")) as! [Task])
			let activitiesBackground = (try? taskContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")) as! [Activity])

			let jobs = (try? context.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Job")) as! [Job])
			let tasks = (try? context.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Task")) as! [Task])
			let activities = (try? context.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")) as! [Activity])

			let syncDate = self.dateFormatterFull.date(from: timestamp)

			self.taskContext.perform {
				for item in trackingItems {
					let id = item["id"] as! String
					let quantity = item["quantity"] as! Double
					var date = item["date"] as! String
					let timeFrom = item["time_from"] as! String
					let timeUntil = item["time_until"] as! String
					let text = item["text"] as! String

					if let timeInterval = self.dateFormatterFull.date(from: date)?.timeIntervalSince1970, timeInterval < 0 {
						date = item["date_created"] as! String
					}

					var dateStart: Date!
					var dateEnd: Date!
					if (timeUntil == "" || timeFrom == "") {
						dateStart = self.dateFormatterFull.date(from: date)
						dateEnd = Calendar.current.date(byAdding: .minute, value: Int(round(quantity * 60)), to: dateStart!)
					} else {
						let trackingDate = self.dateFormatterFull.date(from: date)
						let timeFromDate = Calendar.current.dateComponents([.hour, .minute], from: self.dateFormatterTime.date(from: timeFrom)!)
						let timeUntilDate = Calendar.current.dateComponents([.hour, .minute], from: self.dateFormatterTime.date(from: timeUntil)!)

						dateStart = Calendar.current.date(bySettingHour: timeFromDate.hour!, minute: timeFromDate.minute!, second: 0, of: trackingDate!)
						dateEnd = Calendar.current.date(bySettingHour: timeUntilDate.hour!, minute: timeFromDate.minute!, second: 0, of: trackingDate!)
					}

					if let tracking = self.trackings?.first(where: { $0.id == id }) {
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

						tracking.job = jobObject
						tracking.task = taskObject
						tracking.activity = activityObject
						tracking.date_start = dateStart
						tracking.date_end = dateEnd
						tracking.comment = text
						tracking.exported = SyncStatus.success.rawValue
						tracking.sync = syncDate
					} else {
						var jobObject: Job? = nil
						if let jobId = item["job_id"] as? String, let job = jobsBackground?.first(where: { $0.id == jobId }) {
							jobObject = job
						}

						var activityObject: Activity? = nil
						if let activityId = item["activity_id"] as? String, let activity = activitiesBackground?.first(where: { $0.id == activityId }) {
							activityObject = activity
						}

						var taskObject: Task? = nil
						if let taskId = item["jobtask_id"] as? String, let task = tasksBackground?.first(where: { $0.id == taskId }) {
							taskObject = task
						}

						let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: self.taskContext)
						let tracking = NSManagedObject(entity: entity!, insertInto: self.taskContext)
						let trackingValues: [String: Any?] = [
							"id": id,
							"job": jobObject,
							"task": taskObject,
							"activity": activityObject,
							"date_start": dateStart,
							"date_end": dateEnd,
							"comment": text,
							"exported": SyncStatus.success.rawValue,
							"sync": syncDate
						]

						tracking.setValuesForKeys(trackingValues as [String: Any])
					}
				}

				do {
					try self.taskContext.save()
					seal.fulfill_()
				} catch let error {
					seal.reject(error)
				}
			}
		}
	}

}


extension QuoJob: NSUserNotificationCenterDelegate {

	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}

}
