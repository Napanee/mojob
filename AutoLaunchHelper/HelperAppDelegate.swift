//
//  HelperAppDelegate.swift
//  AutoLaunchHelper
//
//  Created by Martin Schneider on 05.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

@NSApplicationMain
class HelperAppDelegate: NSObject, NSApplicationDelegate {



	func applicationDidFinishLaunching(_ aNotification: Notification) {
		let runningApps = NSWorkspace.shared.runningApplications
		let isRunning = runningApps.contains {
			$0.bundleIdentifier == "de.martinschneider.MoJob"
		}

		if !isRunning {
			var path = Bundle.main.bundlePath as NSString
			for _ in 1...4 {
				path = path.deletingLastPathComponent as NSString
			}
			NSWorkspace.shared.launchApplication(path as String)
		}
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}

