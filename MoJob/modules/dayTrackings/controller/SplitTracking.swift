//
//  SplitTracking.swift
//  MoJob
//
//  Created by Martin Schneider on 02.08.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class SplitTracking: NSViewController {

	@IBOutlet weak var jobsCollectionView: NSCollectionView!
	@IBOutlet weak var jobsCollectionHeight: NSLayoutConstraint!
	@IBOutlet weak var saveButton: NSButton!

	var jobs = QuoJob.shared.jobs
	var sourceTracking: Tracking!
	var jobsCount: Int = 2

	override func viewDidLoad() {
		super.viewDidLoad()

		jobsCollectionView.backgroundColors = [NSColor.clear]

		_configureCollectionView()
	}

	override func viewDidAppear() {
		if let heightJobsCollection = jobsCollectionView.collectionViewLayout?.collectionViewContentSize.height {
			jobsCollectionHeight.constant = heightJobsCollection
		}
	}

	override func viewWillLayout() {
		jobsCollectionView.collectionViewLayout?.invalidateLayout()
	}

	final private func _configureCollectionView() {
		let padding = NSEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
		let flowLayout = NSCollectionViewFlowLayout()
		flowLayout.sectionInset = padding
		flowLayout.minimumLineSpacing = 0

		jobsCollectionView.collectionViewLayout = flowLayout
	}

	@IBAction func addButton(_ sender: NSButton) {
		jobsCount += 1
		jobsCollectionView.insertItems(at: [IndexPath(item: jobsCount - 1, section: 0)])

		if (jobsCount >= 10) {
			sender.isHidden = true
		}

		if let heightJobsCollection = jobsCollectionView.collectionViewLayout?.collectionViewContentSize.height {
			jobsCollectionHeight.constant = heightJobsCollection
		}
	}

	@IBAction func saveButton(_ sender: NSButton) {
		let items = (jobsCollectionView.visibleItems() as! [SplitJobItem]).filter({ $0.jobSelect.indexOfSelectedItem > 0 })

		guard let totalSeconds = sourceTracking.date_end?.timeIntervalSince(sourceTracking.date_start!) else { return }
		let secondsPerItem = round(totalSeconds / Double(items.count) / 60) * 60
		var date_start = sourceTracking.date_start!

		for item in items {
			if let job = jobs?.first(where: { (job) -> Bool in
				guard let title = job.title, let number = job.number else { return false }

				return "\(number) - \(title)" == item.jobSelect.titleOfSelectedItem
			}) {
				let date_end = date_start.addingTimeInterval(TimeInterval(secondsPerItem))
				let values = [
					"job": job,
					"activity": sourceTracking.activity as Any,
					"comment": sourceTracking.comment as Any,
					"date_start": date_start,
					"date_end": date_end,
					"exported": SyncStatus.pending.rawValue
				]

				Tracking.insert(with: values).done({ tracking in
					if let tracking = tracking, let _ = tracking.job {
						tracking.export().done({ _ in }).catch({ _ in })
					}
				}).catch { error in }

				date_start = date_end
			}
		}

		sourceTracking.delete()

		dismiss(self)
	}

}


extension SplitTracking: NSCollectionViewDelegateFlowLayout {

	func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
		return NSSize(width: collectionView.frame.size.width, height: 30)
	}

}

extension SplitTracking: NSCollectionViewDataSource {

	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		return jobsCount
	}

	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SplitJobItem"), for: indexPath)

		guard let collectionViewItem = item as? SplitJobItem else {return item}

		return collectionViewItem
	}

}
