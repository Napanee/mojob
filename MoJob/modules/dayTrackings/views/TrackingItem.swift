//
//  TrackingItem.swift
//  MoJob
//
//  Created by Martin Schneider on 24.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa
import Crashlytics


class TrackingItem: NSView {

	@IBOutlet var contentView: NSView!
	@IBOutlet weak var textView: NSView!
	@IBOutlet var startTimeLabel: NSTextField!
	@IBOutlet var endTimeLabel: NSTextField!
	@IBOutlet var titleLabel: NSTextField!
	@IBOutlet var commentLabel: NSTextField!
	@IBOutlet weak var statusImage: NSButton!
	@IBOutlet var colorSelect: NSStackView!

	var rightClickMenu = NSMenu()
	var indicatorLayer: CALayer! = CALayer()

	var exportStatus: SyncStatus {
		didSet {
			switch exportStatus {
			case .success:
				statusImage.image = NSImage(named: .syncSuccessImage)?.tint(color: NSColor(red: 0.180, green: 0.490, blue: 0.196, alpha: 1))
				statusImage.isEnabled = false
				statusImage.toolTip = "erfolgreich synchronisiert"
			case .error:
				statusImage.image = NSImage(named: .syncErrorImage)?.tint(color: NSColor(red: 0.835, green: 0, blue: 0, alpha: 1))
				statusImage.isEnabled = true
				statusImage.toolTip = "Fehler bei der Synchronisierung\nKlicken, um es erneut zu versuchen"
			case .pending:
				statusImage.image = NSImage(named: .syncPendingImage)?.tint(color: NSColor(red: 0.984, green: 0.753, blue: 0.176, alpha: 1))
				statusImage.isEnabled = false
				statusImage.toolTip = "Synchronisierung läuft"
			}
		}
	}

	var tracking: Tracking? {
		didSet {
			guard let tracking = tracking else { return }
			let formatter = DateFormatter()
			formatter.dateFormat = "HH:mm"

			var title = tracking.custom_job
			if let job = tracking.job {
				title = job.fullTitle
			} else if let customJob = tracking.custom_job {
				title = customJob
			} else if let activity = tracking.activity, let activityTitle = activity.title {
				title = activityTitle
			}

			startTimeLabel.stringValue = formatter.string(from: tracking.date_start!)
			startTimeLabel.toolTip = tracking.date_start?.asString
			if let dateEnd = tracking.date_end {
				endTimeLabel.stringValue = formatter.string(from: dateEnd)
				endTimeLabel.toolTip = tracking.date_end?.asString
			} else {
				endTimeLabel.stringValue = "..."
			}

			titleLabel.stringValue = title ?? "kein Job!"

			if let path = Bundle.main.path(forResource: "MoJob", ofType: "clr"),
				let colors = NSColorList(name: "MoJob", fromFile: path),
				let jobColor = tracking.job?.color,
				let color = colors.color(withKey: jobColor) {
				textView.layer?.backgroundColor = color.withAlphaComponent(0.5).cgColor
				indicatorLayer.backgroundColor = color.cgColor
			}

			if let text = tracking.comment {
				commentLabel.stringValue = text
			} else {
				commentLabel.removeFromSuperview()

				if let superview = titleLabel.superview {
					let constraint = NSLayoutConstraint(item: superview, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: titleLabel, attribute: .bottom, multiplier: 1, constant: 5)
					superview.addConstraint(constraint)
				}
			}
		}
	}

	override init(frame frameRect: NSRect) {
		exportStatus = .pending

		super.init(frame: frameRect)

		commonInit()
	}

	required init?(coder decoder: NSCoder) {
		exportStatus = .pending

		super.init(coder: decoder)

		commonInit()
	}

	private func commonInit() {
		Bundle.main.loadNibNamed("TrackingItem", owner: self, topLevelObjects: nil)
		addSubview(contentView)

		let color: NSColor! = NSColor(red: 0.878, green: 0.878, blue: 0.878, alpha: 1)

		contentView.wantsLayer = true
		contentView.layer?.backgroundColor = CGColor.clear
		contentView.frame = self.bounds
		contentView.autoresizingMask = [.width, .height]

		textView.wantsLayer = true
		textView.layer?.backgroundColor = color.withAlphaComponent(0.5).cgColor

		indicatorLayer.frame = CGRect(x: 0, y: 0, width: 5, height: 200)
		indicatorLayer.backgroundColor = color.cgColor

		textView.layer?.insertSublayer(indicatorLayer, at: 1)

		(statusImage.cell as? NSButtonCell)?.imageDimsWhenDisabled = false
	}

	override func draw(_ dirtyRect: NSRect) {
		if (tracking?.custom_job != nil || tracking?.date_end == nil) {
			statusImage.isHidden = true
		} else {
			statusImage.isHidden = false
		}
	}

	@objc func onContextRestart() {
		guard let source = tracking, let clone = CoreDataHelper.createTracking(in: CoreDataHelper.currentTrackingContext) else { return }

		var keyedValues = source.dictionaryWithValues(forKeys: ["custom_job", "comment", "job", "activity", "task"])

		if let sourceJob = source.job {
			keyedValues["job"] = CoreDataHelper.currentTrackingContext.object(with: sourceJob.objectID)
		}

		if let sourceActivity = source.activity {
			keyedValues["activity"] = CoreDataHelper.currentTrackingContext.object(with: sourceActivity.objectID)
		}

		if let sourceTask = source.task {
			keyedValues["task"] = CoreDataHelper.currentTrackingContext.object(with: sourceTask.objectID)
		}

		clone.setValuesForKeys(keyedValues)

		(NSApp.mainWindow?.windowController as? MainWindowController)?.mainSplitViewController?.showTracking()

		Answers.logCustomEvent(withName: "Tracking", customAttributes: ["Category": "tracking", "Action": "restart"])
	}

	@objc func onContextEdit() {
		if
			tracking?.date_end != nil,
			let daySplitViewController = (NSApp.mainWindow?.windowController as? MainWindowController)?.daySplitViewController
		{
			var editor: EditorController
			if let existingSplitViewItem = daySplitViewController.splitViewItems.first(where: { $0.viewController.isKind(of: EditorController.self) }), let existingEditor = existingSplitViewItem.viewController as? EditorController {
				editor = existingEditor
			} else {
				editor = EditorController(nibName: .editorControllerNib, bundle: nil)

				let splitViewItem = NSSplitViewItem(viewController: editor)
				splitViewItem.isCollapsed = true

				daySplitViewController.insertSplitViewItem(splitViewItem, at: 0)
				daySplitViewController.collapsePanel(0)
			}

			editor.tracking = tracking

			Answers.logCustomEvent(withName: "Tracking", customAttributes: ["Category": "tracking", "Action": "edit on context"])
		}
	}

	@objc func onContextToggleFavorite() {
		if let favorite = CoreDataHelper.favorite(job: tracking?.job, task: tracking?.task, activity: tracking?.activity) {
			CoreDataHelper.deleteFavorite(favorite: favorite)
			Answers.logCustomEvent(withName: "Tracking", customAttributes: ["Category": "favorite", "Action": "delete"])
		} else {
			CoreDataHelper.createFavorite(job: tracking?.job, task: tracking?.task, activity: tracking?.activity)
			Answers.logCustomEvent(withName: "Tracking", customAttributes: ["Category": "favorite", "Action": "create"])
		}

		CoreDataHelper.save()
	}

	@objc func onContextDelete() {
		Answers.logCustomEvent(withName: "Tracking", customAttributes: ["Category": "tracking", "Action": "delete"])

		tracking?.delete()
	}

	@objc func onContextSplit() {
		let splitTrackingVC = SplitTracking(nibName: .splitTrackingNib, bundle: nil)
		splitTrackingVC.sourceTracking = tracking

		let appDelegate = (NSApp.delegate as! AppDelegate)
		appDelegate.window.contentViewController?.presentAsSheet(splitTrackingVC)
	}

	@objc func onContextResetColor() {
		guard let currentJob = tracking?.job, let job = CoreDataHelper.mainContext.object(with: currentJob.objectID) as? Job else { return }
		job.color = nil

		CoreDataHelper.save()

		Answers.logCustomEvent(withName: "Tracking", customAttributes: ["Category": "color", "Action": "reset"])
	}

	override func mouseDown(with event: NSEvent) {
		let modifierFlags = event.modifierFlags

		if (event.clickCount == 1 && modifierFlags.contains(.control)) {
			showContextMenu(with: event)
		}

		if
			event.clickCount == 2,
			tracking?.date_end != nil,
			let daySplitViewController = (NSApp.mainWindow?.windowController as? MainWindowController)?.daySplitViewController
		{
			var editor: EditorController
			if let existingSplitViewItem = daySplitViewController.splitViewItems.first(where: { $0.viewController.isKind(of: EditorController.self) }), let existingEditor = existingSplitViewItem.viewController as? EditorController {
				editor = existingEditor
			} else {
				editor = EditorController(nibName: .editorControllerNib, bundle: nil)

				let splitViewItem = NSSplitViewItem(viewController: editor)
				splitViewItem.isCollapsed = true

				daySplitViewController.insertSplitViewItem(splitViewItem, at: 0)
				daySplitViewController.collapsePanel(0)
			}

			editor.tracking = tracking

			Answers.logCustomEvent(withName: "Tracking", customAttributes: ["Category": "tracking", "Action": "edit with double click"])
		}
	}

	override func rightMouseDown(with event: NSEvent) {
		showContextMenu(with: event)
	}

	private func showContextMenu(with event: NSEvent) {
		if (rightClickMenu.items.count > 0) {
			NSMenu.popUpContextMenu(rightClickMenu, with: event, for: self)
			return
		}

		let restartItem = NSMenuItem(title: "Erneut starten", action: #selector(onContextRestart), keyEquivalent: "")
		rightClickMenu.addItem(restartItem)

		let editItem = NSMenuItem(title: "Bearbeiten", action: #selector(onContextEdit), keyEquivalent: "")
		if (tracking?.date_end == nil) {
			editItem.action = nil
		}
		rightClickMenu.addItem(editItem)

		rightClickMenu.addItem(NSMenuItem.separator())

		let splitItem = NSMenuItem(title: "Aufteilen", action: #selector(onContextSplit), keyEquivalent: "")
		if (tracking?.date_end == nil) {
			splitItem.action = nil
		}
		rightClickMenu.addItem(splitItem)

		let toggleFavoriteItem = NSMenuItem(title: "zu Favoriten hinzufügen", action: #selector(onContextToggleFavorite), keyEquivalent: "")
		if (tracking?.job == nil) {
			toggleFavoriteItem.action = nil
		}
		if let _ = CoreDataHelper.favorite(job: tracking?.job, task: tracking?.task, activity: tracking?.activity) {
			toggleFavoriteItem.title = "von Favoriten entfernen"
		}
		rightClickMenu.addItem(toggleFavoriteItem)

		rightClickMenu.addItem(NSMenuItem.separator())
		let deleteItem = NSMenuItem(title: "Löschen", action: #selector(onContextDelete), keyEquivalent: "")
		if (tracking?.date_end == nil) {
			deleteItem.action = nil
		}
		rightClickMenu.addItem(deleteItem)

		rightClickMenu.addItem(NSMenuItem.separator())
		rightClickMenu.addItem(withTitle: "Color:", action: nil, keyEquivalent: "")
		if let job = tracking?.job, let path = Bundle.main.path(forResource: "MoJob", ofType: "clr"),
			let colors = NSColorList(name: "MoJob", fromFile: path) {
			let buttons = colors.allKeys.map({ (key) -> NSButton in
				let color = colors.color(withKey: key)
				let button = ColorButton(frame: NSRect(x: 0, y: 0, width: 15, height: 15))
				button.target = self
				button.action = #selector(onSelectColor(_:))
				button.color = color
				button.key = key

				if (job.color == key) {
					button.isEnabled = false
				}

				return button
			})

			let stack = NSStackView(views: buttons)
			stack.edgeInsets = NSEdgeInsets(top: 5, left: 22, bottom: 5, right: 22)
			stack.spacing = 5
			stack.setFrameSize(NSSize(width: (buttons.count * 15 + (buttons.count - 1) * 5) + 44, height: 25))

			let menuItem = NSMenuItem()
			menuItem.view = stack
			rightClickMenu.addItem(menuItem)
		} else {
			rightClickMenu.addItem(withTitle: "nicht verfügbar für custom Jobs", action: nil, keyEquivalent: "")
		}
		rightClickMenu.addItem(withTitle: "Farbe zurücksetzen", action: #selector(onContextResetColor), keyEquivalent: "")

		NSMenu.popUpContextMenu(rightClickMenu, with: event, for: self)
	}

	@objc func onSelectColor(_ sender: NSButton) {
		if let button = sender as? ColorButton {
			guard let currentJob = tracking?.job, let job = CoreDataHelper.mainContext.object(with: currentJob.objectID) as? Job else { return }
			job.color = button.key

			Answers.logCustomEvent(withName: "Tracking", customAttributes: ["Category": "color", "Action": "change"])

			CoreDataHelper.save()
			rightClickMenu.cancelTracking()
		}
	}

	@IBAction func statusImage(_ sender: NSButton) {
		guard sender.isEnabled else { return }

		sender.isEnabled = false

		tracking?.export()
	}

}
