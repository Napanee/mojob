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


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	var window: NSWindow!
	var mainWindowController: MainWindowController?

	@IBOutlet weak var syncDataMenuItem: NSMenuItem!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		Fabric.with([Crashlytics.self, Answers.self])

		mainWindowController = MainWindowController()
		mainWindowController!.showWindow(nil)

		if (QuoJob.shared.lastSync?.jobs != nil) {
			QuoJob.shared.checkLoginStatus().done { _ in
				self.syncData()
			}.catch { _ in
				QuoJob.shared.loginWithKeyChain().done {
					self.syncData()
				}.catch { _ in }
			}
		}

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

	@IBAction func loginMenuItem(sender: NSMenuItem) {
		let notificationCenter = NSUserNotificationCenter.default
		let notification = NSUserNotification()
		notification.soundName = NSUserNotificationDefaultSoundName

		QuoJob.shared.sessionId = ""

		QuoJob.shared.checkLoginStatus().done { _ in
			notification.title = "Du wurdest erfolgreich eingeloggt."
			notificationCenter.deliver(notification)
			self.syncDataMenuItem.isEnabled = true
		}.catch { _ in
			QuoJob.shared.loginWithKeyChain().done {
				notification.title = "Du wurdest erfolgreich eingeloggt."
				notificationCenter.deliver(notification)
				self.syncDataMenuItem.isEnabled = true
			}.catch { _ in
				if
					let presentedViewControllers = self.window.contentViewController?.presentedViewControllers,
					let _ = presentedViewControllers.first(where: { $0.isKind(of: Login.self) })
				{
					return
				}

				let loginVC = Login(nibName: .loginNib, bundle: nil)
				self.window.contentViewController?.presentAsSheet(loginVC)
			}
		}
	}

	@IBAction func syncDataMenuItem(sender: NSMenuItem) {
		QuoJob.shared.checkLoginStatus().done { _ in
			self.syncData()
		}.catch { _ in
			QuoJob.shared.loginWithKeyChain().done {
				self.syncData()
			}.catch { _ in
				sender.isEnabled = false
				let notificationCenter = NSUserNotificationCenter.default
				let notification = NSUserNotification()
				notification.title = "Du bist nicht eingeloggt."
				notification.soundName = NSUserNotificationDefaultSoundName
				notificationCenter.deliver(notification)
			}
		}
	}

	// MARK: - Core Data Saving and Undo support

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

}

extension AppDelegate: NSUserNotificationCenterDelegate {

	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}

}
