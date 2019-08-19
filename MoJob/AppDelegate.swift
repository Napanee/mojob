//
//  AppDelegate.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa
import Fabric
import Crashlytics
import LetsMove
import Network
import PromiseKit


@NSApplicationMain
class AppDelegate: NSObject {

	@IBOutlet weak var syncDataMenuItem: NSMenuItem!
	@IBOutlet weak var syncTrackingsMenuItem: NSMenuItem!

	private var _monitor: AnyObject?
	@available(OSX 10.14, *)
	var monitor: NWPathMonitor? {
		get {
			return _monitor as? NWPathMonitor
		}
		set {
			_monitor = newValue
		}
	}

	var window: NSWindow!
	var mainWindowController: MainWindowController?
	var hasInternalConnection: Bool = false
	var hasExternalConnection: Bool = false

	private var timerSleep: Date?

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		Fabric.with([Crashlytics.self, Answers.self])
		UserDefaults.standard.register(defaults: [
			"NSInitialToolTipDelay": 1,
			"NSApplicationCrashOnExceptions": true
		])

		mainWindowController = MainWindowController()
		mainWindowController!.showWindow(nil)

		if (QuoJob.shared.jobs.count == 0) {
			QuoJob.shared.login().done({ _ in
				GlobalNotification.shared.deliverNotification(
					withTitle: "Initiale Daten werden geladen.",
					andInformationtext: "Dies kann bis zu einer Minute dauern, aber ich sage Bescheid, wenn ich fertig bin 😉"
				)
			}).catch({ _ in })
		}

//		QuoJob.shared.syncData().catch { error in
//			GlobalNotification.shared.deliverNotification(withTitle: "Fehler beim Synchronisieren", andInformationtext: error.localizedDescription)
//		}

		PFMoveToApplicationsFolderIfNecessary()

		GlobalTimer.shared.startNoTrackingTimer()

		NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(onScreenDidSleep(notification:)), name: NSWorkspace.screensDidSleepNotification, object: nil) // lock screen
		NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(onScreenDidWake(notification:)), name: NSWorkspace.screensDidWakeNotification, object: nil) // return from locked screen

		NSUserNotificationCenter.default.delegate = self

		if #available(OSX 10.14, *) {
			let queue = DispatchQueue(label: "Monitor")
			monitor?.pathUpdateHandler = { path in
				DispatchQueue.main.sync {
					self.networkChanged()
				}
			}
			monitor?.start(queue: queue)
		}
	}

	@available(OSX 10.14, *)
	private func networkChanged() {
		let status = monitor?.currentPath.status

//		switch status {
//		case .satisfied:
//			if (!hasExternalConnection || !hasInternalConnection) {
//				QuoJob.shared.isConnectionPossible().done({ result in
//					if (!self.hasInternalConnection) {
//						GlobalNotification.shared.deliverNotification(withTitle: "VPN-Verbindung gefunden.", andInformationtext: "Kann losgehen.")
//					}
//
//					self.hasInternalConnection = true
//				}).catch({ error in
//					if (self.hasInternalConnection) {
//						GlobalNotification.shared.deliverNotification(withTitle: "Keine VPN-Verbindung.", andInformationtext: error.localizedDescription)
//					}
//				})
//
//				if (!self.hasExternalConnection) {
//					GlobalNotification.shared.deliverNotification(withTitle: "Du bist online.")
//				}
//
//				hasExternalConnection = true
//			}
//		case .unsatisfied:
//			if (hasExternalConnection) {
//				GlobalNotification.shared.deliverNotification(withTitle: "Du bist offline.", andInformationtext: "Stelle eine Internetverbindung her, damit deine Trackings an QuoJob übertragen werden können.")
//				hasExternalConnection = false
//			}
//		case .requiresConnection:
//			print("requiresConnection")
//		}

		if (status == .unsatisfied) { // offline
		}
	}

	@IBAction func openWebappMenuItem(sender: NSMenuItem) {
		let url = URL(string: "https://mojob.moccu")!
		NSWorkspace.shared.open(url)
	}

	@IBAction func loginMenuItem(sender: NSMenuItem) {
		QuoJob.shared.sessionId = ""

		QuoJob.shared.login().done({ _ in
			GlobalNotification.shared.deliverNotification(withTitle: "Du wurdest erfolgreich eingeloggt.", andInformationtext: nil)
			self.syncDataMenuItem.isEnabled = true
		}).catch({ error in
			if
				let presentedViewControllers = self.window.contentViewController?.presentedViewControllers,
				presentedViewControllers.filter({ $0.isKind(of: Login.self) }).count > 0
			{
				return
			}

			let loginVC = Login(nibName: .loginNib, bundle: nil)
			self.window.contentViewController?.presentAsSheet(loginVC)
		})
	}

	@IBAction func syncDataMenuItem(sender: NSMenuItem) {
		QuoJob.shared.syncData().catch { error in
			sender.isEnabled = false
			GlobalNotification.shared.deliverNotLoggedIn(withInformationText: "Logge dich ein, um die QuoJob-Daten zu synchronisieren.")
		}
	}

	// MARK: - Sleephandling

	@objc private func onScreenDidSleep(notification: NSNotification) {
		guard CoreDataHelper.shared.currentTracking != nil else {
			GlobalTimer.shared.stopNoTrackingTimer()
			return
		}

		if
			let presentedViewControllers = self.window.contentViewController?.presentedViewControllers,
			let presentedViewController = presentedViewControllers.first(where: { $0.isKind(of: WakeUp.self) })
		{
			presentedViewController.dismiss(self)
		}

		timerSleep = Date()
	}

	@objc private func onScreenDidWake(notification: NSNotification) {
		guard CoreDataHelper.shared.currentTracking != nil else {
			GlobalTimer.shared.startNoTrackingTimer()
			return
		}

		let alertVC = WakeUp(nibName: .wakeUpController, bundle: nil)
		alertVC.sleepTime = timerSleep
		window.contentViewController?.presentAsModalWindow(alertVC)
	}

}

// MARK: - Core Data Saving and Undo support
extension AppDelegate: NSApplicationDelegate {

	func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
		// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
		return CoreDataHelper.context.undoManager
	}

	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		guard let currentTracking = CoreDataHelper.shared.currentTracking else { return .terminateNow }

		let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
		let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info")
		let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
		let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
		let alert = NSAlert()
		alert.messageText = question
		alert.informativeText = info
		alert.addButton(withTitle: quitButton)
		alert.addButton(withTitle: cancelButton)

		let answer = alert.runModal()
		if answer == .alertFirstButtonReturn {
			currentTracking.delete()
			return .terminateNow
		}

		return .terminateCancel
	}

	func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
		if (flag) {
			window.orderFront(self)
		} else {
			window.makeKeyAndOrderFront(self)
		}

		return true
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	//	@IBAction func saveAction(_ sender: AnyObject?) {
	//		// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
	//		let context = persistentContainer.viewContext
	//
	//		if !context.commitEditing() {
	//			NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
	//		}
	//		if context.hasChanges {
	//			do {
	//				try context.save()
	//			} catch {
	//				// Customize this code block to include application-specific recovery steps.
	//				let nserror = error as NSError
	//				NSApplication.shared.presentError(nserror)
	//			}
	//		}
	//	}

}

extension AppDelegate: NSUserNotificationCenterDelegate {

	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}

}
