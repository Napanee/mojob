//
//  QuoJob.swift
//  MoJob
//
//  Created by Martin Schneider on 24.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import PromiseKit
import Alamofire
import Crashlytics
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

	let dateFormatterFullUTC = DateFormatter()
	let dateFormatterFullLocal = DateFormatter()
	let dateFormatterTime = DateFormatter()
	var results: [[String: Any]] = []
	var defaultParams: [String: Any] {
		get {
			return ["session": sessionId]
		}
	}

	var keychain: Keychain!
	var userId: String = ""
	var sessionId: String = ""

	let context = CoreDataHelper.mainContext
	let backgroundContext: NSManagedObjectContext = {
		let parent = CoreDataHelper.mainContext
		let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)

		context.parent = parent

		return context
	}()

	private override init() {
		super.init()

		NSUserNotificationCenter.default.delegate = self

		dateFormatterFullUTC.dateFormat = "YYYYMMddHHmmss"
		dateFormatterFullUTC.timeZone = TimeZone(abbreviation: "UTC")
		dateFormatterFullLocal.dateFormat = "YYYYMMddHHmmss"

		dateFormatterTime.dateFormat = "HHmm"
	}

	func fetch(as method: QuoJob.Method, with params: [String: Any]) -> Promise<[String: Any]> {
//		print("fetch \(method)")
		let utilityQueue = DispatchQueue.global(qos: .utility)
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
							case 4002: // Hourbooking is NOT deletable
								seal.reject(ApiError.withMessage("Hourbooking is NOT deletable"))
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

	func exportTracking(tracking: Tracking) -> Promise<(id: String, timestamp: Date)> {
		var id: String? = nil
		var bookingTypeString: String! = "abw"
		var activityId: String! = nil
		var taskId: String! = nil

		if let trackingId = tracking.id {
			id = trackingId
		}

		if let bookingType = CoreDataHelper.types().first(where: { $0.id == tracking.job?.type?.id }) {
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

		return firstly(execute: {
			return login()
		}).then({ _ -> Promise<[String: Any]> in
			var params = self.defaultParams
			params["hourbooking"] = [
				"id": id,
				"date": self.dateFormatterFullUTC.string(from: tracking.date_end! as Date),
				"time_from": self.dateFormatterTime.string(from: tracking.date_start! as Date),
				"time_until": self.dateFormatterTime.string(from: tracking.date_end! as Date),
				"job_id": tracking.job?.id,
				"activity_id": activityId,
				"jobtask_id": taskId,
				"text": tracking.comment,
				"booking_type": bookingTypeString
			]

			return self.fetch(as: .myTime_putHourbooking, with: params)
		}).then({ result -> Promise<(id: String, timestamp: Date)> in
			return Promise { seal in
				if
					let hourbooking = result["hourbooking"] as? [String: Any],
					let id = hourbooking["id"] as? String,
					let timestamp = hourbooking["date_created"] as? String,
					let date = self.dateFormatterFullLocal.date(from: timestamp)
				{
					seal.fulfill((id: id, timestamp: date.addingTimeInterval(1)))
				}
			}
		})
	}

	func deleteTracking(tracking: Tracking) -> Promise<Void> {
		return Promise { seal in
			login().then({ _ -> Promise<[String: Any]> in
				var params = self.defaultParams
				params["hourbooking_id"] = tracking.id

				return self.fetch(as: .myTime_deleteHourbooking, with: params)
			}).done({ _ in
				seal.fulfill_()
			}).catch({ error in
				GlobalNotification.shared.deliverNotification(withTitle: "Fehler beim Löschen.", andInformationtext: error.localizedDescription)
				seal.reject(error)
			})
		}
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
		let params: [String: Any] = [
			"user": userName,
			"device_id": "foo",
			"client_type": "MoJobApp",
			"language": "de",
			"password": password.MD5,
			"min_version": 1,
			"max_version": 6
		]

		return fetch(as: .session_login, with: params).done { result in
			guard let userId = result["user_id"] as? String, let sessionId = result["session"] as? String else {
				return
			}

			self.userId = userId
			self.sessionId = sessionId

			Crashlytics.sharedInstance().setUserName(userName)
		}
	}

	func loginWithKeyChain() -> Promise<Void> {
		keychain = Keychain(service: KEYCHAIN_NAMESPACE)
		let keys = keychain.allKeys()

		if keys.count > 0, let name = keys.first, let pass = try? keychain.get(name) {
			return Promise { seal in
				loginWithUserData(userName: name, password: pass).done({
					seal.fulfill_()
				}).catch({ error in
					if (error.localizedDescription == errorMessages.wrongPassword || error.localizedDescription == errorMessages.notFound) {
						self.keychain[name] = nil
					}

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
		let start = Date()

		results = []

		return login().done({ result -> Void in
			if (CoreDataHelper.jobs().count == 0) {
				GlobalNotification.shared.deliverNotification(
					withTitle: "Initiale Daten werden geladen.",
					andInformationtext: "Dies kann bis zu einer Minute dauern. Ich sage Bescheid, wenn ich fertig bin ⏳"
				)
			}

			when(fulfilled: self.fetchJobTypes(), self.fetchActivities())
				.then { (resultTypes, resultActivities) -> Promise<Void> in
					return when(fulfilled: self.handleJobTypes(with: resultTypes), self.handleActivities(with: resultActivities))
				}.then { _ -> Promise<[String: Any]> in
					return self.fetchJobs()
				}.then { resultJobs -> Promise<Void> in
					return self.handleJobs(with: resultJobs)
				}.then { _ -> Promise<[String: Any]> in
					return self.fetchTasks()
				}.then { resultTasks -> Promise<Void> in
					return self.handleTasks(with: resultTasks)
				}.then { _ -> Promise<[String: Any]> in
					return self.fetchTrackings()
				}.then { resultTrackings -> Promise<Void> in
					return self.handleTrackings(with: resultTrackings)
				}.done { _ in
					CoreDataHelper.save()

					let end = Date()
					let diff = end.timeIntervalSince(start)
					var calendar = Calendar.current
					calendar.locale = Locale(identifier: "de")
					let formatter = DateComponentsFormatter()
					formatter.unitsStyle = .full
					formatter.zeroFormattingBehavior = .dropAll
					formatter.allowedUnits = [.minute, .second]
					formatter.calendar = calendar

					var title: String = ""
					var text: String = ""

					if (self.results.count == 0) {
						title = "Daten aktuell."
						text = "Du bist startklar."
					} else {
						title = "Daten erfolgreich synchronisiert."
						text = "Es wurden "

						text += self.results
							.sorted(by: { ($0["order"] as! Int) < ($1["order"] as! Int) })
							.map({ type in
								return type["text"] as! String
							}).joined(separator: ", ")

						if let seconds = formatter.string(from: diff) {
							text += " in \(seconds)"
						}

						text += " synchronisiert."
					}

					GlobalNotification.shared.deliverNotification(withTitle: title, andInformationtext: text)
				}.catch({ error in
					print("SyncError: \(error)")
				})
		})
	}

	func lastSyncDate(for entityName: String) -> Date? {
		let keypathExpression = NSExpression(forKeyPath: "sync")
		let maxExpression = NSExpression(forFunction: "max:", arguments: [keypathExpression])
		let expressionDescription = NSExpressionDescription()
		let key = "maxSync"
		expressionDescription.name = key
		expressionDescription.expression = maxExpression
		expressionDescription.expressionResultType = .dateAttributeType

		let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
		request.propertiesToFetch = [expressionDescription]
		request.resultType = .dictionaryResultType

		if let lastSync = try? CoreDataHelper.mainContext.fetch(request) as? [[String: Any]] {
			return lastSync[0]["maxSync"] as? Date
		}

		return nil
	}

	func fetchJobTypes() -> Promise<[String: Any]> {
		var params = defaultParams

		if let lastSync = lastSyncDate(for: "Type") {
			params["last_sync"] = dateFormatterFullUTC.string(from: lastSync)
		}

//		print(params)

		return fetch(as: .job_getJobtypes, with: params)
	}

	func fetchJobs() -> Promise<[String: Any]> {
		var params = defaultParams

		if let lastSync = lastSyncDate(for: "Job") {
			params["last_sync"] = dateFormatterFullUTC.string(from: lastSync)
		}

//		print(params)

		return fetch(as: .job_getJobs, with: params)
	}

	func fetchActivities() -> Promise<[String: Any]> {
		var params = defaultParams

		if let lastSync = lastSyncDate(for: "Activity") {
			params["last_sync"] = dateFormatterFullUTC.string(from: lastSync)
		}

//		print(params)

		return fetch(as: .common_getActivities, with: params)
	}

	func fetchTasks(with ids: [String]? = nil) -> Promise<[String: Any]> {
		var params = defaultParams

		if let ids = ids {
			params["jobtask_ids"] = ids
		} else if let lastSync = lastSyncDate(for: "Task") {
			params["last_sync"] = dateFormatterFullUTC.string(from: lastSync)
		}

//		print(params)

		return fetch(as: .job_getJobtasks, with: params)
	}

	func fetchTrackings() -> Promise<[String: Any]> {
		var params = defaultParams
		params["filter"] = [
			"user_id": userId
		]

		if let lastSync = lastSyncDate(for: "Tracking") {
			params["last_sync"] = dateFormatterFullUTC.string(from: lastSync)
		}

//		print(params)

		return fetch(as: .myTime_getHourbookings, with: params)
	}

	private func handleJobTypes(with result: [String: Any]) -> Promise<Void> {
		return Promise { seal in
			guard var typeItems = result["jobtypes"] as? [[String: Any]], let timestamp = result["timestamp"] as? String, typeItems.count > 0 else {
				seal.fulfill_()
				return
			}

			let syncDate = self.dateFormatterFullUTC.date(from: timestamp)

			typeItems = typeItems.filter({
				if let active = $0["active"] as? Bool {
					return active
				}

				return false
			})

			let typesBackground = try? backgroundContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Type")) as? [Type]

			backgroundContext.perform {
				for item in typeItems {
					let id = item["id"] as! String
					let title = item["name"] as! String
					let active = item["active"] as! Bool
					let internalService = item["internal"] as! Bool
					let productiveService = item["productive"] as! Bool

//					print("task \(id)")

					if let type = typesBackground?.first(where: { $0.id == id }) {
//						print("existing")
						type.title = title
						type.active = active
						type.internal_service = internalService
						type.productive_service = productiveService
						type.sync = syncDate
					} else {
//						print("neu")
						let entity = NSEntityDescription.entity(forEntityName: "Type", in: self.backgroundContext)
						let type = NSManagedObject(entity: entity!, insertInto: self.backgroundContext)
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
					try self.backgroundContext.save()
					seal.fulfill_()
				} catch let error {
					seal.reject(error)
				}
			}
		}
	}

	func handleJobs(with result: [String: Any]) -> Promise<Void> {
		return Promise { seal in
			guard let jobItems = result["jobs"] as? [[String: Any]], let timestamp = result["timestamp"] as? String, jobItems.count > 0 else {
				seal.fulfill_()
				return
			}

			let syncDate = self.dateFormatterFullUTC.date(from: timestamp)

			let newJobs = jobItems.filter({(($0["bookable"] as? Bool) ?? false) && ($0["assigned_user_ids"] as! [String]).contains(self.userId)})
			if (newJobs.count > 0) {
				results.append(["type": "jobs", "order": 1, "text": "\(String(newJobs.count)) Jobs"])
			}

			let jobsBackground = try? backgroundContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Job")) as? [Job]
			let typesBackground = try? backgroundContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Type")) as? [Type]

			backgroundContext.perform {
				for item in jobItems {
					let id = item["id"] as! String
					let number = item["number"] as! String
					let bookable = item["bookable"] as! Bool
					let title = item["title"] as! String
					let typeId = item["job_type_id"] as! String
					let assigned_user_ids = item["assigned_user_ids"] as! [String]
					let isAssigned = assigned_user_ids.contains(self.userId)
					let type = typesBackground?.first(where: { $0.id == typeId})

//					print("job \(id)")

					if let job = jobsBackground?.first(where: { $0.id == id }) {
//						print("existing")
						job.assigned = isAssigned
						job.bookable = bookable
						job.number = number
						job.title = title
						job.type = type
						job.sync = syncDate
					} else {
//						print("neu")
						let entity = NSEntityDescription.entity(forEntityName: "Job", in: self.backgroundContext)
						let job = NSManagedObject(entity: entity!, insertInto: self.backgroundContext)
						let jobValues: [String: Any] = [
							"id": id,
							"title": title,
							"number": number,
							"assigned": isAssigned,
							"bookable": bookable,
							"type": type as Any,
							"sync": syncDate as Any
						]
						job.setValuesForKeys(jobValues)
					}
				}

				do {
					try self.backgroundContext.save()
					seal.fulfill_()
				} catch let error {
					seal.reject(error)
				}
			}
		}
	}

	func handleActivities(with result: [String: Any]) -> Promise<Void> {
		return Promise { seal in
			guard var activityItems = result["activities"] as? [[String: Any]], let timestamp = result["timestamp"] as? String, activityItems.count > 0 else {
				seal.fulfill_()
				return
			}

			let syncDate = self.dateFormatterFullUTC.date(from: timestamp)

			activityItems = activityItems.filter({ $0["active"] as? Bool ?? false })

			let activitiesBackground = try? backgroundContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")) as? [Activity]

			backgroundContext.perform {
				for item in activityItems {
					let id = item["id"] as! String
					let title = item["name"] as! String
					let internal_service = item["internal"] as! Bool
					let external_service = item["external_service"] as! Bool
					let nfc = item["nfc"] as! Bool

//					print("activity \(id)")

					if let activity = activitiesBackground?.first(where: { $0.id == id }) {
//						print("existing")
						activity.title = title
						activity.internal_service = internal_service
						activity.external_service = external_service
						activity.nfc = nfc
						activity.sync = syncDate
					} else {
//						print("neu")
						let entity = NSEntityDescription.entity(forEntityName: "Activity", in: self.backgroundContext)
						let activity = NSManagedObject(entity: entity!, insertInto: self.backgroundContext)
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
					try self.backgroundContext.save()
					seal.fulfill_()
				} catch let error {
					seal.reject(error)
				}
			}
		}
	}

	func handleTasks(with result: [String: Any], updateTimestamp: Bool = true) -> Promise<Void> {
		return Promise { seal in
			guard let taskItems = result["jobtasks"] as? [[String: Any]], let timestamp = result["timestamp"] as? String, taskItems.count > 0 else {
				seal.fulfill_()
				return
			}
			
			var syncDate = self.lastSyncDate(for: "Task")

			if (updateTimestamp) {
				syncDate = self.dateFormatterFullUTC.date(from: timestamp)
			}

			let jobsAll = CoreDataHelper.jobs(in: backgroundContext).filter({ $0.assigned && $0.bookable }).map({ $0.id })
			let resultTasks = taskItems.filter({ jobsAll.contains($0["job_id"] as? String) && !($0["done"] as? Bool ?? true) })
			if (resultTasks.count > 0) {
				self.results.append(["type": "tasks", "order": 2, "text": "\(String(resultTasks.count)) Aufgaben"])
			}

			let jobsBackground = try? backgroundContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Job")) as? [Job]
			let tasksBackground = try? backgroundContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Task")) as? [Task]
			let activitiesBackground = try? backgroundContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")) as? [Activity]

			backgroundContext.perform {
				for item in taskItems {
					let id = item["id"] as! String
					let title = item["subject"] as! String
					let jobId = item["job_id"] as? String
					let activityId = item["activity_id"] as? String
					let status = item["status"] as! String
					let active = item["active"] as! Int
					var done = item["done"] as! Bool

					done = done || status != "active" || active != 1
//					print("task \(id)")

					let job = jobsBackground?.first(where: { $0.id == jobId })
					let activity = activitiesBackground?.first(where: { $0.id == activityId })

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

					if let task = tasksBackground?.first(where: { $0.id == id }) {
//						print("existing")
						task.title = title
						task.hours_planned = hoursPlaned
						task.hours_booked = hoursBooked
						task.job = job
						task.activity = activity
						task.done = done
						task.sync = syncDate
					} else {
//						print("neu")
						let entity = NSEntityDescription.entity(forEntityName: "Task", in: self.backgroundContext)
						let task = NSManagedObject(entity: entity!, insertInto: self.backgroundContext)
						let taskValues: [String: Any] = [
							"id": id,
							"title": title,
							"hours_planned": hoursPlaned,
							"hours_booked": hoursBooked,
							"job": job as Any,
							"activity": activity as Any,
							"done": done,
							"sync": syncDate as Any
						]
						task.setValuesForKeys(taskValues)
					}
				}

				do {
					try self.backgroundContext.save()
					seal.fulfill_()
				} catch let error {
					seal.reject(error)
				}
			}
		}
	}

	func handleTrackings(with result: [String: Any]) -> Promise<Void> {
		return Promise { seal in
			guard let trackingItems = result["hourbookings"] as? [[String: Any]], let timestamp = result["timestamp"] as? String, trackingItems.count > 0 else {
				seal.fulfill_()
				return
			}

			let jobsBackground = try? backgroundContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Job")) as? [Job]
			let tasksBackground = try? backgroundContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Task")) as? [Task]
			let activitiesBackground = try? backgroundContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")) as? [Activity]
			let trackingsBackground = try? backgroundContext.fetch(NSFetchRequest<NSFetchRequestResult>(entityName: "Tracking")) as? [Tracking]

			let syncDate = self.dateFormatterFullUTC.date(from: timestamp)

			if (trackingItems.count > 0) {
				results.append(["type": "trackings", "order": 3, "text": "\(String(trackingItems.count)) Trackings"])
			}

			backgroundContext.perform {
				for item in trackingItems {
					let id = item["id"] as! String
					let quantity = item["quantity"] as! Double
					var date = item["date"] as! String
					let timeFrom = item["time_from"] as! String
					let text = item["text"] as! String

//					print("tracking \(id)")

					if let timeInterval = self.dateFormatterFullUTC.date(from: date)?.timeIntervalSince1970, timeInterval < 0 {
						date = item["date_created"] as! String
					}

					let indexTimeFrom = String.Index(utf16Offset: 4, in: "\(timeFrom)0000")
					let newTimeFrom = String("\(timeFrom)0000"[..<indexTimeFrom])
					let trackingDate = self.dateFormatterFullUTC.date(from: date)
					let timeFromDate = Calendar.current.dateComponents([.hour, .minute], from: self.dateFormatterTime.date(from: newTimeFrom)!)
					let dateStart = Calendar.current.date(bySettingHour: timeFromDate.hour!, minute: timeFromDate.minute!, second: 0, of: trackingDate!)
					let dateEnd = Calendar.current.date(byAdding: .minute, value: Int(round(quantity * 60)), to: dateStart!)

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

					if let tracking = trackingsBackground?.first(where: { $0.id == id }) {
//						print("existing")
						let comment = text != "" ? text : nil

						tracking.job = jobObject
						tracking.task = taskObject
						tracking.activity = activityObject
						tracking.date_start = dateStart
						tracking.date_end = dateEnd
						tracking.comment = comment
						tracking.exported = SyncStatus.success.rawValue
						tracking.sync = syncDate
					} else {
//						print("neu")
						let entity = NSEntityDescription.entity(forEntityName: "Tracking", in: self.backgroundContext)
						let tracking = NSManagedObject(entity: entity!, insertInto: self.backgroundContext)
						let trackingValues: [String: Any?] = [
							"id": id,
							"job": jobObject,
							"task": taskObject,
							"activity": activityObject,
							"date_start": dateStart,
							"date_end": dateEnd,
							"comment": text != "" ? text : nil,
							"exported": SyncStatus.success.rawValue,
							"sync": syncDate
						]

						tracking.setValuesForKeys(trackingValues as [String: Any])
					}
				}

				do {
					try self.backgroundContext.save()
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
