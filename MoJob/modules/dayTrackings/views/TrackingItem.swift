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

	var indicatorLayer: CALayer! = CALayer()

	var exportStatus: SyncStatus {
		didSet {
			switch exportStatus {
			case .success:
				statusImage.image = NSImage(named: "sync-success")
				statusImage.isEnabled = false
			case .error:
				statusImage.image = NSImage(named: "sync-error")
				statusImage.isEnabled = true
			case .pending:
				statusImage.image = NSImage(named: "sync-pending")
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

			if let text = tracking.comment {
				commentLabel.stringValue = text
			} else {
				commentLabel.removeFromSuperview()

				if let superview = titleLabel.superview {
					let constraint = NSLayoutConstraint(item: superview, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: titleLabel, attribute: .bottom, multiplier: 1, constant: 5)
					superview.addConstraint(constraint)
				}
			}

//			if let color = tracking.color as? NSColor {
//				textView.layer?.backgroundColor = color.withAlphaComponent(0.5).cgColor
//				indicatorLayer.backgroundColor = color.cgColor
//			}
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

		var color: NSColor! = NSColor.clear
		if let colorList = NSColorList.availableColorLists.first(where: { $0.name == "System" }) {
			let systemColors = colorList.allKeys.filter({ $0.hasPrefix("system")})

			if let colorName = systemColors.randomElement() {
				color = colorList.color(withKey: colorName)
			}
		}

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
	}

	override func mouseDown(with event: NSEvent) {
//		if let theHitView = view.window?.contentView?.hitTest((view.window?.mouseLocationOutsideOfEventStream)!) {
			if (event.clickCount == 2) {
				let window = (NSApp.delegate as! AppDelegate).window
				if let tracking = tracking, let contentViewController = window?.contentViewController as? SplitViewController {
					contentViewController.showEditor(with: tracking)
				}
			}
//		}
	}

	@IBAction func statusImage(_ sender: NSButton) {
		guard sender.isEnabled else { return }

		let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
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
