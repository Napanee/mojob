//
//  enums.swift
//  MoJob
//
//  Created by Martin Schneider on 08.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//


enum nibNames {
	static let NavigationController = "NavigationController"
	static let JobListController = "JobListController"
	static let FavoritesCollectionItem = "FavoriteItem"
	static let JobsCollectionItem = "JobItem"
	static let TrackingViewController = "TrackingViewController"
	static let DayTrackingsController = "DayTrackingsController"
	static let EditorController = "EditorController"
}

enum errorMessages {
	static let missingRights = "Dein QuoJob-Account ist nicht für die API freigeschaltet. Bitte wende dich an den QuoJob-Verantwortlichen."
	static let notFound = "User nicht gefunden"
	static let wrongPassword = "Userdaten nicht korrekt"
	static let sessionProblem = "Du bist ausgeloggt. Logge dich bei QuoJob ein, um deine Trackings übertragen zu können."
	static let disabled = "Dein QuoJob-Account ist gesperrt. Bitte wende dich an den QuoJob-Verantwortlichen."
	static let unknown = "Unbekannter Fehler. Bitte wende dich an Martin."
	static let vpnProblem = "Du bist nicht per VPN mit dem Moccu-Netzwerk verbunden. Deine Trackings werden nicht an QuoJob übertragen."
	static let offline = "Du bist offline. Stelle eine Internetverbindung her und versuche es noch einmal."
}

enum SyncStatus: String {
	case pending = "pending"
	case error = "error"
	case success = "success"
}
