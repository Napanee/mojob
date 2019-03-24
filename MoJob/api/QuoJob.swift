//
//  QuoJob.swift
//  MoJob
//
//  Created by Martin Schneider on 24.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Alamofire
import Foundation


#if DEVELOPMENT
	let API_URL = "https://mojob-test.moccu/index.php?rpc=1"
#else
	let API_URL = "https://mojob.moccu/index.php?rpc=1"
#endif


class QuoJob {

	var sessionId: String! = ""

	static func isLoggedIn(success: @escaping () -> Void, failed: @escaping (_ error: Int) -> Void, err: @escaping (_ error: String) -> Void) {
		let verifyParams: [String: Any] = [
			"jsonrpc": "2.0",
			"method": "session.get_current_user",
			"params": [
				"session": "sessionId"
			],
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
					* 2001 User NOT found
					* 2002 Wrong password
					* 2003 No session given
					* 2004 Invalid session
					*/
					if ([2000, 2001, 2002, 2003, 2004].contains(statusCode)) {
						failed(statusCode)
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

}
