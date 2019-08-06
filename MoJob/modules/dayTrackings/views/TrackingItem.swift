//
//  TrackingItem.swift
//  MoJob
//
//  Created by Martin Schneider on 24.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


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
				statusImage.image = NSImage(named: "sync-success")?.tint(color: NSColor(red: 0.106, green: 0.369, blue: 0.125, alpha: 1))
				statusImage.isEnabled = false
			case .error:
				statusImage.image = NSImage(named: "sync-error")?.tint(color: NSColor(red: 0.835, green: 0, blue: 0, alpha: 1))
				statusImage.isEnabled = true
			case .pending:
				statusImage.image = NSImage(named: "sync-pending")?.tint(color: NSColor(red: 0.992, green: 0.847, blue: 0.208, alpha: 1))
				statusImage.isEnabled = false
			}
		}
	}

	var tracking: Tracking? {
		didSet {
			guard let tracking = tracking else { return }
			let formatter = DateFormatter()
			formatter.dateFormat = "HH:mm"

			var title = tracking.custom_job
			if let job = tracking.job, let jobTitle = job.title {
				title = jobTitle
			}

			startTimeLabel.stringValue = formatter.string(from: tracking.date_start!)
			endTimeLabel.stringValue = formatter.string(from: tracking.date_end!)
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
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		if (tracking?.custom_job != nil) {
			statusImage.isHidden = true
		} else {
			statusImage.isHidden = false
		}
	}

	override func rightMouseDown(with event: NSEvent) {
		if (rightClickMenu.items.count > 0) {
			return
		}

		rightClickMenu.addItem(withTitle: "Bearbeiten", action: #selector(onContextEdit), keyEquivalent: "")
		rightClickMenu.addItem(withTitle: "Löschen", action: #selector(onContextDelete), keyEquivalent: "")

		if let path = Bundle.main.path(forResource: "MoJob", ofType: "clr"),
			let colors = NSColorList(name: "MoJob", fromFile: path) {
			let buttons = colors.allKeys.map({ (key) -> NSButton in
				let color = colors.color(withKey: key)
				let button = ColorButton(frame: NSRect(x: 0, y: 0, width: 15, height: 15))
				button.target = self
				button.action = #selector(onSelectColor(_:))
				button.color = color
				button.key = key

				return button
			})

			let stack = NSStackView(views: buttons)
			stack.edgeInsets = NSEdgeInsets(top: 5, left: 22, bottom: 5, right: 22)
			stack.spacing = 5
			stack.setFrameSize(NSSize(width: (buttons.count * 15 + (buttons.count - 1) * 5) + 44, height: 25))

			let menuItem = NSMenuItem()
			menuItem.view = stack
			rightClickMenu.addItem(NSMenuItem.separator())
			rightClickMenu.addItem(withTitle: "Color:", action: nil, keyEquivalent: "")
			rightClickMenu.addItem(menuItem)
		}

		if (tracking?.custom_job != nil) {
			rightClickMenu.addItem(NSMenuItem.separator())
			rightClickMenu.addItem(withTitle: "Aufteilen", action: #selector(onContextSplit), keyEquivalent: "")
		}

		NSMenu.popUpContextMenu(rightClickMenu, with: event, for: self)
	}

	@objc func onContextEdit() {
		if let tracking = tracking, let appDelegate = NSApp.delegate as? AppDelegate, let mainWindowController = appDelegate.mainWindowController, let contentViewController = mainWindowController.currentContentViewController as? TrackingSplitViewController {
			contentViewController.showEditor(with: tracking)
		}
	}

	@objc func onContextDelete() {
		tracking?.delete()
	}

	@objc func onContextSplit() {
		let splitTrackingVC = SplitTracking(nibName: "SplitTracking", bundle: nil)
		splitTrackingVC.sourceTracking = tracking

		let appDelegate = (NSApp.delegate as! AppDelegate)
		appDelegate.window.contentViewController?.presentAsSheet(splitTrackingVC)
	}

	override func mouseDown(with event: NSEvent) {
//		if let theHitView = view.window?.contentView?.hitTest((view.window?.mouseLocationOutsideOfEventStream)!) {
			if (event.clickCount == 2) {
				if let tracking = tracking, let appDelegate = NSApp.delegate as? AppDelegate, let mainWindowController = appDelegate.mainWindowController, let contentViewController = mainWindowController.currentContentViewController as? TrackingSplitViewController {
					contentViewController.showEditor(with: tracking)
				}
			}
//		}
	}

	@objc func onSelectColor(_ sender: NSButton) {
		if let button = sender as? ColorButton {
			let context = CoreDataHelper.shared.persistentContainer.viewContext
			tracking?.job?.color = button.key
			try? context.save()

			rightClickMenu.cancelTracking()
		}
	}

	@IBAction func statusImage(_ sender: NSButton) {
		guard sender.isEnabled else { return }

		let context = CoreDataHelper.shared.persistentContainer.viewContext
		if let tracking = tracking {
			QuoJob.shared.exportTracking(tracking: tracking).done { result in
				if
					let hourbooking = result["hourbooking"] as? [String: Any],
					let id = hourbooking["id"] as? String
				{
					tracking.id = id
					tracking.exported = SyncStatus.success.rawValue
					sender.isEnabled = false
					try context.save()
				}
			}.catch { error in
				tracking.exported = SyncStatus.error.rawValue
				try? context.save()
			}
		}
	}

}
