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
				statusImage.image = NSImage(named: .syncSuccessImage)?.tint(color: NSColor(red: 0.180, green: 0.490, blue: 0.196, alpha: 1))
				statusImage.isEnabled = false
			case .error:
				statusImage.image = NSImage(named: .syncErrorImage)?.tint(color: NSColor(red: 0.835, green: 0, blue: 0, alpha: 1))
				statusImage.isEnabled = true
			case .pending:
				statusImage.image = NSImage(named: .syncPendingImage)?.tint(color: NSColor(red: 0.984, green: 0.753, blue: 0.176, alpha: 1))
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
			} else if let activity = tracking.activity, let activityTitle = activity.title {
				title = activityTitle
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

		(statusImage.cell as? NSButtonCell)?.imageDimsWhenDisabled = false
	}

	override func draw(_ dirtyRect: NSRect) {
		if (tracking?.custom_job != nil) {
			statusImage.isHidden = true
		} else {
			statusImage.isHidden = false
		}
	}

	override func rightMouseDown(with event: NSEvent) {
		if (rightClickMenu.items.count > 0) {
			NSMenu.popUpContextMenu(rightClickMenu, with: event, for: self)
			return
		}

		rightClickMenu.addItem(withTitle: "Bearbeiten", action: #selector(onContextEdit), keyEquivalent: "")

		rightClickMenu.addItem(NSMenuItem.separator())

		let splitItem = NSMenuItem(title: "Aufteilen", action: nil, keyEquivalent: "")
		splitItem.action = tracking?.custom_job != nil ? #selector(onContextSplit) : nil
		rightClickMenu.addItem(splitItem)

		let toggleFavoriteItem = NSMenuItem(title: "zu Favoriten hinzufügen", action: nil, keyEquivalent: "")
		toggleFavoriteItem.action = tracking?.job != nil ? #selector(onContextToggleFavorite) : nil
		if let job = tracking?.job, job.isFavorite {
			toggleFavoriteItem.title = "von Favoriten entfernen"
		}
		rightClickMenu.addItem(toggleFavoriteItem)

		rightClickMenu.addItem(NSMenuItem.separator())
		rightClickMenu.addItem(withTitle: "Löschen", action: #selector(onContextDelete), keyEquivalent: "")

		rightClickMenu.addItem(NSMenuItem.separator())
		rightClickMenu.addItem(withTitle: "Color:", action: nil, keyEquivalent: "")
		if let _ = tracking?.job, let path = Bundle.main.path(forResource: "MoJob", ofType: "clr"),
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
			rightClickMenu.addItem(menuItem)
		} else {
			rightClickMenu.addItem(withTitle: "nicht verfügbar für custom Jobs", action: nil, keyEquivalent: "")
		}

		NSMenu.popUpContextMenu(rightClickMenu, with: event, for: self)
	}

	@objc func onContextEdit() {
		if let tracking = tracking, let appDelegate = NSApp.delegate as? AppDelegate, let mainWindowController = appDelegate.mainWindowController, let contentViewController = mainWindowController.currentContentViewController as? EditorSplitViewController {
			contentViewController.showEditor(with: tracking)
		}
	}

	@objc func onContextToggleFavorite() {
		if let isFavorite = tracking?.job?.isFavorite {
			tracking?.job?.update(with: ["isFavorite": !isFavorite])
			CoreDataHelper.saveContext()
		}
	}

	@objc func onContextDelete() {
		tracking?.delete()
	}

	@objc func onContextSplit() {
		let splitTrackingVC = SplitTracking(nibName: .splitTrackingNib, bundle: nil)
		splitTrackingVC.sourceTracking = tracking

		let appDelegate = (NSApp.delegate as! AppDelegate)
		appDelegate.window.contentViewController?.presentAsSheet(splitTrackingVC)
	}

	override func mouseDown(with event: NSEvent) {
//		if let theHitView = view.window?.contentView?.hitTest((view.window?.mouseLocationOutsideOfEventStream)!) {
			if (event.clickCount == 2) {
				if let tracking = tracking, let appDelegate = NSApp.delegate as? AppDelegate, let mainWindowController = appDelegate.mainWindowController, let contentViewController = mainWindowController.currentContentViewController as? EditorSplitViewController {
					contentViewController.showEditor(with: tracking)
				}
			}
//		}
	}

	@objc func onSelectColor(_ sender: NSButton) {
		if let button = sender as? ColorButton, let job = tracking?.job {
			job.update(with: ["color": button.key])
			CoreDataHelper.saveContext()
			rightClickMenu.cancelTracking()
		}
	}

	@IBAction func statusImage(_ sender: NSButton) {
		guard sender.isEnabled else { return }

		sender.isEnabled = false

		tracking?.export()
	}

}
