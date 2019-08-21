//
//  Job.swift
//  MoJob
//
//  Created by Martin Schneider on 06.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Foundation
import CoreData
import PromiseKit


extension Job {

	var fullTitle: String {
		get {
			return "\(self.number ?? "no number") - \(self.title ?? "no title")"
		}
	}

}

