//
//  enums.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa


enum nibNames {
	static let NavigationController = "NavigationController"
	static let JobListController = "JobListController"
	static let FavoritesCollectionItem = "FavoriteItem"
	static let JobsCollectionItem = "JobItem"
	static let TrackingViewController = "TrackingViewController"
	static let DayTrackingsController = "DayTrackingsController"
	static let EditorController = "EditorController"
}

extension NSImage.Name {
	static let delete = NSImage.Name("delete")
	static let play = NSImage.Name("play")
	static let stop = NSImage.Name("stop")
}
