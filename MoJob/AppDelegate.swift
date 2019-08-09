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


@NSApplicationMain
class AppDelegate: NSObject {

	var window: NSWindow!
	var mainWindowController: MainWindowController?
	private var timerSleep: Date?

	@IBOutlet weak var syncDataMenuItem: NSMenuItem!
	@IBOutlet weak var syncTrackingsMenuItem: NSMenuItem!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		Fabric.with([Crashlytics.self, Answers.self])

		mainWindowController = MainWindowController()
		mainWindowController!.showWindow(nil)

		if (QuoJob.shared.lastSync?.jobs != nil) {
			QuoJob.shared.syncData().catch { error in
				let notificationCenter = NSUserNotificationCenter.default
				let notification = NSUserNotification()
				notification.title = "Du bist nicht eingeloggt."
				notification.informativeText = "Damit deine Trackings automatisch übertragen werden können, solltest du dich einloggen."
				notification.soundName = NSUserNotificationDefaultSoundName
				notificationCenter.deliver(notification)
			}
		}

		PFMoveToApplicationsFolderIfNecessary()

		GlobalTimer.shared.startNoTrackingTimer()

		NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(onScreenDidSleep(notification:)), name: NSWorkspace.screensDidSleepNotification, object: nil) // lock screen
		NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(onScreenDidWake(notification:)), name: NSWorkspace.screensDidWakeNotification, object: nil) // return from locked screen

		NSUserNotificationCenter.default.delegate = self
	}

	func syncData() {
		QuoJob.shared.syncData()
			.done {
				print("done!")
			}
			.catch { error in
				//Handle error or give feedback to the user
				print(error.localizedDescription)
		}
	}

	func syncTrackings() {
		QuoJob.shared.syncTrackings()
			.done {
				print("done!")
			}
			.catch { error in
				//Handle error or give feedback to the user
				print(error.localizedDescription)
			}
	}

	@IBAction func openWebappMenuItem(sender: NSMenuItem) {
		let url = URL(string: "https://mojob.moccu")!
		NSWorkspace.shared.open(url)
	}

	@IBAction func loginMenuItem(sender: NSMenuItem) {
		let notificationCenter = NSUserNotificationCenter.default
		let notification = NSUserNotification()
		notification.soundName = NSUserNotificationDefaultSoundName

		QuoJob.shared.sessionId = ""

		QuoJob.shared.login().done({ _ in
			notification.title = "Du wurdest erfolgreich eingeloggt."
			notificationCenter.deliver(notification)
			self.syncDataMenuItem.isEnabled = true
		}).catch({ error in
			if
				let presentedViewControllers = self.window.contentViewController?.presentedViewControllers,
				let _ = presentedViewControllers.first(where: { $0.isKind(of: Login.self) })
			{
				return
			}

			let loginVC = Login(nibName: .loginNib, bundle: nil)
			self.window.contentViewController?.presentAsSheet(loginVC)
		})
	}

	@IBAction func syncDataMenuItem(sender: NSMenuItem) {
		QuoJob.shared.syncData().done {
			print("done!")
		}.catch { error in
			sender.isEnabled = false
			let notificationCenter = NSUserNotificationCenter.default
			let notification = NSUserNotification()
			notification.title = "Du bist nicht eingeloggt."
			notification.soundName = NSUserNotificationDefaultSoundName
			notificationCenter.deliver(notification)
		}
	}

	@IBAction func syncTrackingsMenuItem(sender: NSMenuItem) {
		QuoJob.shared.syncTrackings().done {
			print("done!")
		}.catch { _ in
			sender.isEnabled = false
			let notificationCenter = NSUserNotificationCenter.default
			let notification = NSUserNotification()
			notification.title = "Du bist nicht eingeloggt."
			notification.soundName = NSUserNotificationDefaultSoundName
			notificationCenter.deliver(notification)
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
		return CoreDataHelper.shared.persistentContainer.viewContext.undoManager
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
