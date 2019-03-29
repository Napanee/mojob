//
//  QuoJob.swift
//  MoJob
//
//  Created by Martin Schneider on 24.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Alamofire
import Foundation
import KeychainAccess


#if DEVELOPMENT
	let API_URL = "https://mojob-test.moccu/index.php?rpc=1"
#else
	let API_URL = "https://mojob.moccu/index.php?rpc=1"
#endif


class QuoJob {

	static let shared = QuoJob()
	var keychain: Keychain!
	var userId: String!
	var sessionId: String! = "" {
		didSet {
			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateSession"), object: nil)
		}
	}

	private init() {
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

	func loginWithUserData(userName: String, password: String, success: @escaping () -> Void, failed: @escaping (_ statusCode: Int) -> Void) {
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

		Alamofire.request(API_URL, method: .post, parameters: parameters, encoding: JSONEncoding.default)
			.responseJSON { response in switch response.result {
				case .success(let JSON):
					let response = JSON as! NSDictionary
					if (response.allKeys.contains(where: { ($0 as! String) == "error" })) {
						if let error = response.object(forKey: "error")! as? NSDictionary, let statusCode = error.object(forKey: "code")! as? String {
							print(statusCode)
							failed(Int(statusCode)!)
						}
					} else if let result = response.object(forKey: "result")! as? NSDictionary {
						self.userId = result.object(forKey: "user_id")! as? String
						self.sessionId = result.object(forKey: "session")! as? String

	//					Crashlytics.sharedInstance().setUserName(userName)
	//					Answers.logLogin(withMethod: "userData", success: true, customAttributes: [:])

						success()
					}
				case .failure(let error):
	//				Answers.logLogin(withMethod: "userData", success: false, customAttributes: [:])
					print("Request failed with error: \(error)")
			}
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
