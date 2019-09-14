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
	var appMenu = NSMenu()
	var hasInternalConnection: Bool = false
	var hasExternalConnection: Bool = false
	var statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: 60)
	var userDefaults = UserDefaults()

	private var timerSleep: Date?

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		Fabric.with([Crashlytics.self, Answers.self])
		UserDefaults.standard.register(defaults: [
			"NSInitialToolTipDelay": 1,
			"NSApplicationCrashOnExceptions": true
		])

		mainWindowController = MainWindowController()
		mainWindowController!.showWindow(nil)

		if (CoreDataHelper.jobs().count == 0) {
			QuoJob.shared.login().done({ _ in
				GlobalNotification.shared.deliverNotification(
					withTitle: "Initiale Daten werden geladen.",
					andInformationtext: "Dies kann bis zu einer Minute dauern, aber ich sage Bescheid, wenn ich fertig bin 😉"
				)
			}).catch({ _ in })
		}

		if (
			(userDefaults.object(forKey: UserDefaults.Keys.crashOnSync) == nil || !userDefaults.bool(forKey: UserDefaults.Keys.crashOnSync)) &&
			(userDefaults.object(forKey: UserDefaults.Keys.syncOnStart) == nil || userDefaults.bool(forKey: UserDefaults.Keys.syncOnStart)))
		{
			QuoJob.shared.syncData().catch { error in
				GlobalNotification.shared.deliverNotification(withTitle: "Fehler beim Synchronisieren", andInformationtext: error.localizedDescription)
			}
		}

		userDefaults.set(true, forKey: UserDefaults.Keys.crashOnSync)

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
		} else {
			let alert = NSAlert()
			alert.alertStyle = .critical
			alert.messageText = "Betriebssystem veraltet!"
			alert.informativeText = "Wegen DIR muss ich hier extra Code schreiben. Mach endlich ein Update! 😤"
			alert.addButton(withTitle: "Es tut mir leid")
			alert.addButton(withTitle: "Mir doch egal")

			alert.runModal()
		}

		initStatusBarApp()
	}

	private func initStatusBarApp() {
		guard let statusBarButton = statusItem.button, let icon = NSImage(named: .statusBarImage) else { return }

		icon.isTemplate = true
		icon.size = NSSize(width: 12, height: 12)
		statusBarButton.image = icon

		statusBarButton.imagePosition = .imageRight
		statusBarButton.alignment = .left

		var attributes: [NSAttributedString.Key: Any] = [:]
		attributes[NSAttributedString.Key.baselineOffset] = -0.9
		attributes[NSAttributedString.Key.font] = NSFont.systemFont(ofSize: 11, weight: .medium)
		let attributed = NSAttributedString(string: "00:00", attributes: attributes)
		statusBarButton.attributedTitle = attributed

		if #available(OSX 10.14, *) {
			statusBarButton.wantsLayer = true
			let layer = CALayer()
			layer.frame = CGRect(x: 0, y: 3, width: statusBarButton.bounds.width, height: statusBarButton.bounds.height - 6)
			layer.cornerRadius = 4.0
			layer.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.4).cgColor
			statusBarButton.layer?.addSublayer(layer)
		}

		appMenu.removeAllItems()

		let keypathExpression = NSExpression(forKeyPath: "date_end")
		let maxExpression = NSExpression(forFunction: "max:", arguments: [keypathExpression])
		let expressionDescription = NSExpressionDescription()
		let key = "maxDateEnd"
		expressionDescription.name = key
		expressionDescription.expression = maxExpression
		expressionDescription.expressionResultType = .dateAttributeType

		let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Tracking")
		request.propertiesToFetch = ["job.id", "job.number", "job.title", expressionDescription]
		request.propertiesToGroupBy = ["job.id", "job.number", "job.title"]
		request.fetchLimit = 5
		request.resultType = .dictionaryResultType
		request.sortDescriptors = [
			NSSortDescriptor(key: "date_end", ascending: false)
		]

		appMenu.addItem(NSMenuItem(title: "MoJob anzeigen", action: #selector(openApp(_:)), keyEquivalent: ""))
		appMenu.addItem(NSMenuItem.separator())

		if let trackings = try? CoreDataHelper.mainContext.fetch(request) as? [[String: Any]] {
			for tracking in trackings {
				let item = NSMenuItem(title: "\(tracking["job.number"]!) - \(tracking["job.title"]!)", action: #selector(startTracking(with:)), keyEquivalent: "")
				item.representedObject = tracking["job.id"]!
				appMenu.addItem(item)
			}
		}

		appMenu.addItem(NSMenuItem.separator())
		appMenu.addItem(NSMenuItem(title: "MoJob schließen", action: #selector(quitApp(_:)), keyEquivalent: ""))

		statusItem.menu = appMenu
	}

	@objc private func startTracking(with sender: NSMenuItem) {
		guard let jobId = sender.representedObject as? String else { return }

		if let newTracking = CoreDataHelper.createTracking(in: CoreDataHelper.currentTrackingContext) {
			let jobs = CoreDataHelper.jobs(in: CoreDataHelper.currentTrackingContext)
			let job = jobs.first(where: { $0.id == jobId })
			newTracking.job = job
			((NSApp.delegate as? AppDelegate)?.window.windowController as? MainWindowController)?.mainSplitViewController?.showTracking()
		}
	}

	@objc private func openApp(_ sender: NSMenuItem) {
		NSApp.setActivationPolicy(.regular)
		window?.center()
		window?.makeKeyAndOrderFront(nil)
		NSApp.activate(ignoringOtherApps: true)
	}

	@objc private func quitApp(_ sender: NSMenuItem) {
		NSApp.terminate(self)
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
		guard CoreDataHelper.currentTracking != nil else {
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
		guard let currentTracking = CoreDataHelper.currentTracking else {
			GlobalTimer.shared.startNoTrackingTimer()
			return
		}

		if (currentTracking.duration > 60) {
			let alertVC = WakeUp(nibName: .wakeUpController, bundle: nil)
			alertVC.sleepTime = timerSleep
			window.contentViewController?.presentAsModalWindow(alertVC)
		}
	}

}

// MARK: - Core Data Saving and Undo support
extension AppDelegate: NSApplicationDelegate {

	func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
		// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
		return CoreDataHelper.mainContext.undoManager
	}

	func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
		guard let currentTracking = CoreDataHelper.currentTracking else { return .terminateNow }

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
		userDefaults.set(false, forKey: UserDefaults.Keys.crashOnSync)
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
