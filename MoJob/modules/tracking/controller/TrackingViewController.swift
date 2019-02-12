//
//  TrackingViewController.swift
//  MoJob
//
//  Created by Martin Schneider on 10.02.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class TrackingViewController: NSViewController {

	var timer = Timer()
	var timeInSec = 0
	var counter: CGFloat = 0

	@IBOutlet weak var timerCount: TimerCount!
	@IBOutlet weak var timeLabel: NSTextField!

	override func viewDidLoad() {
        super.viewDidLoad()

		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }

	@objc func updateTime() {
		counter = counter + 1

		if (counter > 60) {
			counter = 1
		}

		timeInSec = timeInSec + 1
		timerCount.counter = counter
		timeLabel.stringValue = secondsToHoursMinutesSeconds(sec: timeInSec)
	}
    
}
