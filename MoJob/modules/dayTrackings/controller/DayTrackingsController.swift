//
//  DayTrackingsController.swift
//  MoJob
//
//  Created by Martin Schneider on 23.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class DayTrackingsController: NSViewController {

	@IBOutlet weak var dateDay: NSTextField!
	@IBOutlet weak var dateMonth: NSTextField!
	@IBOutlet weak var dateYear: NSTextField!
	@IBOutlet weak var totalTimeForDay: NSTextField!
	@IBOutlet weak var trackingsStackView: TrackingsStackView!

	@IBOutlet weak var btn: NSButton!

	let context = (NSApp.delegate as! AppDelegate).persistentContainer.viewContext
	var _fetchedResultsControllerTrackings: NSFetchedResultsController<Tracking>? = nil
	var fetchedResultControllerTrackings: NSFetchedResultsController<Tracking> {
		if (_fetchedResultsControllerTrackings != nil) {
			return _fetchedResultsControllerTrackings!
		}

		let fetchRequest: NSFetchRequest<Tracking> = Tracking.fetchRequest()

		fetchRequest.predicate = NSPredicate(format: "date_end != nil")

		fetchRequest.sortDescriptors = [
			NSSortDescriptor(key: "date_start", ascending: true)
		]

		let resultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

		_fetchedResultsControllerTrackings = resultsController

		do {
			try _fetchedResultsControllerTrackings!.performFetch()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror)")
		}

		return _fetchedResultsControllerTrackings!
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		var endTime: Date?
		guard let trackings = fetchedResultControllerTrackings.fetchedObjects else { return }

		for tracking in trackings {
			if let endTime = endTime, tracking.date_start!.timeIntervalSince(endTime) > 60 {
				trackingsStackView.insertAddButton()
			}

			let trackingView = TrackingItem()
			trackingView.tracking = tracking

			trackingsStackView.addView(trackingView, in: .bottom)

				}
			}

			endTime = tracking.date_end
		}
	}

}
