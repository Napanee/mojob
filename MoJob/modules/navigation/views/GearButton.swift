//
//  GearButton.swift
//  MoJob
//
//  Created by Martin Schneider on 25.09.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa

class GearButton: BaseButton {

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		colorForegroundDefault.setStroke()
		colorBackgroundDefault.setFill()

		if (!isEnabled) {
			colorBackgroundInverted.setFill()
		}

		let gearPath = NSBezierPath()
		gearPath.move(to: NSPoint(x: 29.32, y: 12.95))
		gearPath.curve(to: NSPoint(x: 28.39, y: 12.07), controlPoint1: NSPoint(x: 29.25, y: 12.48), controlPoint2: NSPoint(x: 28.86, y: 12.12))
		gearPath.line(to: NSPoint(x: 26.28, y: 11.85))
		gearPath.curve(to: NSPoint(x: 26.15, y: 11.74), controlPoint1: NSPoint(x: 26.24, y: 11.85), controlPoint2: NSPoint(x: 26.16, y: 11.78))
		gearPath.curve(to: NSPoint(x: 25.19, y: 9.43), controlPoint1: NSPoint(x: 25.91, y: 10.94), controlPoint2: NSPoint(x: 25.59, y: 10.16))
		gearPath.curve(to: NSPoint(x: 25.2, y: 9.26), controlPoint1: NSPoint(x: 25.17, y: 9.39), controlPoint2: NSPoint(x: 25.18, y: 9.29))
		gearPath.line(to: NSPoint(x: 26.55, y: 7.62))
		gearPath.curve(to: NSPoint(x: 26.58, y: 6.33), controlPoint1: NSPoint(x: 26.85, y: 7.25), controlPoint2: NSPoint(x: 26.86, y: 6.72))
		gearPath.curve(to: NSPoint(x: 25.25, y: 4.75), controlPoint1: NSPoint(x: 26.13, y: 5.71), controlPoint2: NSPoint(x: 25.7, y: 5.2))
		gearPath.curve(to: NSPoint(x: 23.68, y: 3.43), controlPoint1: NSPoint(x: 24.81, y: 4.31), controlPoint2: NSPoint(x: 24.29, y: 3.87))
		gearPath.curve(to: NSPoint(x: 22.39, y: 3.46), controlPoint1: NSPoint(x: 23.3, y: 3.15), controlPoint2: NSPoint(x: 22.75, y: 3.17))
		gearPath.line(to: NSPoint(x: 20.75, y: 4.8))
		gearPath.curve(to: NSPoint(x: 20.57, y: 4.81), controlPoint1: NSPoint(x: 20.74, y: 4.81), controlPoint2: NSPoint(x: 20.7, y: 4.83))
		gearPath.curve(to: NSPoint(x: 18.27, y: 3.86), controlPoint1: NSPoint(x: 19.84, y: 4.41), controlPoint2: NSPoint(x: 19.07, y: 4.09))
		gearPath.curve(to: NSPoint(x: 18.15, y: 3.73), controlPoint1: NSPoint(x: 18.22, y: 3.84), controlPoint2: NSPoint(x: 18.16, y: 3.77))
		gearPath.line(to: NSPoint(x: 17.94, y: 1.62))
		gearPath.curve(to: NSPoint(x: 17.05, y: 0.68), controlPoint1: NSPoint(x: 17.89, y: 1.14), controlPoint2: NSPoint(x: 17.52, y: 0.76))
		gearPath.curve(to: NSPoint(x: 12.95, y: 0.68), controlPoint1: NSPoint(x: 15.52, y: 0.44), controlPoint2: NSPoint(x: 14.48, y: 0.44))
		gearPath.curve(to: NSPoint(x: 12.06, y: 1.62), controlPoint1: NSPoint(x: 12.47, y: 0.76), controlPoint2: NSPoint(x: 12.11, y: 1.14))
		gearPath.line(to: NSPoint(x: 11.85, y: 3.73))
		gearPath.curve(to: NSPoint(x: 11.73, y: 3.86), controlPoint1: NSPoint(x: 11.84, y: 3.77), controlPoint2: NSPoint(x: 11.78, y: 3.84))
		gearPath.curve(to: NSPoint(x: 9.35, y: 4.83), controlPoint1: NSPoint(x: 10.93, y: 4.09), controlPoint2: NSPoint(x: 10.16, y: 4.41))
		gearPath.curve(to: NSPoint(x: 9.25, y: 4.81), controlPoint1: NSPoint(x: 9.3, y: 4.83), controlPoint2: NSPoint(x: 9.26, y: 4.81))
		gearPath.line(to: NSPoint(x: 7.61, y: 3.46))
		gearPath.curve(to: NSPoint(x: 6.32, y: 3.42), controlPoint1: NSPoint(x: 7.25, y: 3.16), controlPoint2: NSPoint(x: 6.7, y: 3.15))
		gearPath.curve(to: NSPoint(x: 4.75, y: 4.75), controlPoint1: NSPoint(x: 5.71, y: 3.87), controlPoint2: NSPoint(x: 5.19, y: 4.31))
		gearPath.curve(to: NSPoint(x: 3.42, y: 6.33), controlPoint1: NSPoint(x: 4.3, y: 5.2), controlPoint2: NSPoint(x: 3.87, y: 5.71))
		gearPath.curve(to: NSPoint(x: 3.46, y: 7.62), controlPoint1: NSPoint(x: 3.14, y: 6.71), controlPoint2: NSPoint(x: 3.15, y: 7.24))
		gearPath.line(to: NSPoint(x: 4.8, y: 9.26))
		gearPath.curve(to: NSPoint(x: 4.81, y: 9.43), controlPoint1: NSPoint(x: 4.82, y: 9.29), controlPoint2: NSPoint(x: 4.83, y: 9.39))
		gearPath.curve(to: NSPoint(x: 3.85, y: 11.74), controlPoint1: NSPoint(x: 4.41, y: 10.16), controlPoint2: NSPoint(x: 4.09, y: 10.93))
		gearPath.curve(to: NSPoint(x: 3.72, y: 11.85), controlPoint1: NSPoint(x: 3.84, y: 11.78), controlPoint2: NSPoint(x: 3.76, y: 11.85))
		gearPath.line(to: NSPoint(x: 1.61, y: 12.06))
		gearPath.curve(to: NSPoint(x: 0.67, y: 12.95), controlPoint1: NSPoint(x: 1.13, y: 12.11), controlPoint2: NSPoint(x: 0.75, y: 12.48))
		gearPath.curve(to: NSPoint(x: 0.5, y: 15), controlPoint1: NSPoint(x: 0.56, y: 13.7), controlPoint2: NSPoint(x: 0.5, y: 14.37))
		gearPath.curve(to: NSPoint(x: 0.68, y: 17.05), controlPoint1: NSPoint(x: 0.5, y: 15.63), controlPoint2: NSPoint(x: 0.56, y: 16.31))
		gearPath.curve(to: NSPoint(x: 1.61, y: 17.94), controlPoint1: NSPoint(x: 0.75, y: 17.53), controlPoint2: NSPoint(x: 1.14, y: 17.89))
		gearPath.line(to: NSPoint(x: 3.72, y: 18.15))
		gearPath.curve(to: NSPoint(x: 3.85, y: 18.27), controlPoint1: NSPoint(x: 3.76, y: 18.16), controlPoint2: NSPoint(x: 3.84, y: 18.22))
		gearPath.curve(to: NSPoint(x: 4.81, y: 20.57), controlPoint1: NSPoint(x: 4.09, y: 19.07), controlPoint2: NSPoint(x: 4.41, y: 19.84))
		gearPath.curve(to: NSPoint(x: 4.8, y: 20.75), controlPoint1: NSPoint(x: 4.83, y: 20.62), controlPoint2: NSPoint(x: 4.82, y: 20.72))
		gearPath.line(to: NSPoint(x: 3.46, y: 22.39))
		gearPath.curve(to: NSPoint(x: 3.42, y: 23.68), controlPoint1: NSPoint(x: 3.15, y: 22.76), controlPoint2: NSPoint(x: 3.14, y: 23.29))
		gearPath.curve(to: NSPoint(x: 4.75, y: 25.25), controlPoint1: NSPoint(x: 3.87, y: 24.29), controlPoint2: NSPoint(x: 4.3, y: 24.81))
		gearPath.curve(to: NSPoint(x: 6.32, y: 26.58), controlPoint1: NSPoint(x: 5.19, y: 25.7), controlPoint2: NSPoint(x: 5.71, y: 26.13))
		gearPath.curve(to: NSPoint(x: 7.61, y: 26.54), controlPoint1: NSPoint(x: 6.7, y: 26.86), controlPoint2: NSPoint(x: 7.25, y: 26.84))
		gearPath.line(to: NSPoint(x: 9.25, y: 25.2))
		gearPath.curve(to: NSPoint(x: 9.43, y: 25.19), controlPoint1: NSPoint(x: 9.26, y: 25.19), controlPoint2: NSPoint(x: 9.31, y: 25.18))
		gearPath.curve(to: NSPoint(x: 11.73, y: 26.14), controlPoint1: NSPoint(x: 10.16, y: 25.59), controlPoint2: NSPoint(x: 10.93, y: 25.91))
		gearPath.curve(to: NSPoint(x: 11.85, y: 26.28), controlPoint1: NSPoint(x: 11.78, y: 26.16), controlPoint2: NSPoint(x: 11.84, y: 26.24))
		gearPath.line(to: NSPoint(x: 12.06, y: 28.39))
		gearPath.curve(to: NSPoint(x: 12.95, y: 29.33), controlPoint1: NSPoint(x: 12.11, y: 28.87), controlPoint2: NSPoint(x: 12.48, y: 29.25))
		gearPath.curve(to: NSPoint(x: 15, y: 29.5), controlPoint1: NSPoint(x: 13.7, y: 29.44), controlPoint2: NSPoint(x: 14.37, y: 29.5))
		gearPath.curve(to: NSPoint(x: 17.05, y: 29.33), controlPoint1: NSPoint(x: 15.63, y: 29.5), controlPoint2: NSPoint(x: 16.3, y: 29.44))
		gearPath.curve(to: NSPoint(x: 17.94, y: 28.39), controlPoint1: NSPoint(x: 17.53, y: 29.25), controlPoint2: NSPoint(x: 17.89, y: 28.87))
		gearPath.line(to: NSPoint(x: 18.15, y: 26.28))
		gearPath.curve(to: NSPoint(x: 18.27, y: 26.15), controlPoint1: NSPoint(x: 18.16, y: 26.24), controlPoint2: NSPoint(x: 18.22, y: 26.16))
		gearPath.curve(to: NSPoint(x: 20.65, y: 25.18), controlPoint1: NSPoint(x: 19.07, y: 25.91), controlPoint2: NSPoint(x: 19.84, y: 25.59))
		gearPath.curve(to: NSPoint(x: 20.75, y: 25.2), controlPoint1: NSPoint(x: 20.7, y: 25.18), controlPoint2: NSPoint(x: 20.74, y: 25.19))
		gearPath.line(to: NSPoint(x: 22.39, y: 26.55))
		gearPath.curve(to: NSPoint(x: 23.68, y: 26.58), controlPoint1: NSPoint(x: 22.75, y: 26.84), controlPoint2: NSPoint(x: 23.31, y: 26.86))
		gearPath.curve(to: NSPoint(x: 25.26, y: 25.25), controlPoint1: NSPoint(x: 24.29, y: 26.14), controlPoint2: NSPoint(x: 24.81, y: 25.7))
		gearPath.curve(to: NSPoint(x: 26.58, y: 23.68), controlPoint1: NSPoint(x: 25.7, y: 24.81), controlPoint2: NSPoint(x: 26.13, y: 24.3))
		gearPath.curve(to: NSPoint(x: 26.55, y: 22.39), controlPoint1: NSPoint(x: 26.86, y: 23.29), controlPoint2: NSPoint(x: 26.85, y: 22.76))
		gearPath.line(to: NSPoint(x: 25.2, y: 20.75))
		gearPath.curve(to: NSPoint(x: 25.19, y: 20.57), controlPoint1: NSPoint(x: 25.18, y: 20.72), controlPoint2: NSPoint(x: 25.17, y: 20.62))
		gearPath.curve(to: NSPoint(x: 26.15, y: 18.27), controlPoint1: NSPoint(x: 25.59, y: 19.85), controlPoint2: NSPoint(x: 25.91, y: 19.07))
		gearPath.curve(to: NSPoint(x: 26.27, y: 18.15), controlPoint1: NSPoint(x: 26.16, y: 18.22), controlPoint2: NSPoint(x: 26.24, y: 18.16))
		gearPath.line(to: NSPoint(x: 28.39, y: 17.94))
		gearPath.curve(to: NSPoint(x: 29.32, y: 17.05), controlPoint1: NSPoint(x: 28.86, y: 17.89), controlPoint2: NSPoint(x: 29.25, y: 17.53))
		gearPath.curve(to: NSPoint(x: 29.5, y: 15), controlPoint1: NSPoint(x: 29.44, y: 16.31), controlPoint2: NSPoint(x: 29.5, y: 15.63))
		gearPath.curve(to: NSPoint(x: 29.32, y: 12.95), controlPoint1: NSPoint(x: 29.5, y: 14.37), controlPoint2: NSPoint(x: 29.44, y: 13.7))
		gearPath.close()
		gearPath.lineWidth = lineWidth
		gearPath.miterLimit = 4
		gearPath.lineJoinStyle = .round
		gearPath.fill()
		gearPath.stroke()

		if (!isEnabled) {
			colorBackgroundDefault.setFill()
		}


		let circlePath = NSBezierPath(ovalIn: NSRect(x: 7.5, y: 7.5, width: 15, height: 15))
		circlePath.lineWidth = lineWidth
		circlePath.fill()
		circlePath.stroke()

	}

}
