//
//  Login.swift
//  MoJob
//
//  Created by Martin Schneider on 24.03.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//

import Cocoa
import KeychainAccess


class Login: NSViewController {

	var keychain: Keychain!

	@IBOutlet weak var generalErrorLabel: NSTextField!
	@IBOutlet weak var usernameTextField: TextField!
	@IBOutlet weak var usernameErrorLabel: NSTextField!
	@IBOutlet weak var passwordTextField: Password!
	@IBOutlet weak var passwordErrorLabel: NSTextField!
	@IBOutlet weak var storeInKeyChain: NSButton!

	override func viewDidLoad() {
		super.viewDidLoad()

		let pstyle = NSMutableParagraphStyle()
		pstyle.firstLineHeadIndent = 5.0
		storeInKeyChain.attributedTitle = NSAttributedString(
			string: storeInKeyChain.title,
			attributes: [
				NSAttributedString.Key.paragraphStyle: pstyle
			]
		)

		view.wantsLayer = true
		view.layer?.backgroundColor = NSColor.white.cgColor

		generalErrorLabel.isHidden = true
		usernameErrorLabel.isHidden = true
		passwordErrorLabel.isHidden = true
	}

	private func loginSuccess() {
		let name = usernameTextField.stringValue
		let pass = passwordTextField.stringValue

		if (storeInKeyChain.state == .on) {
			keychain = Keychain(service: "de.mojobapp-dev.login")
			keychain[name] = pass
		}

		DispatchQueue.main.async {
			self.dismiss(self)
		}
	}

	@IBAction func submit(_ sender: NSButton) {
		let name = usernameTextField.stringValue
		let pass = passwordTextField.stringValue

		generalErrorLabel.isHidden = true
		usernameErrorLabel.isHidden = true
		passwordErrorLabel.isHidden = true

		if (name == "" || pass == "") {
			generalErrorLabel.stringValue = "Du musst einen Usernamen und ein Passwort eingeben."

			NSAnimationContext.beginGrouping()
			NSAnimationContext.current.duration = 0.5
			generalErrorLabel.animator().isHidden = false
			NSAnimationContext.endGrouping()

			return
		}

		QuoJob.shared.loginWithUserData(
			userName: name,
			password: pass,
			success: self.loginSuccess,
			failed: { statusCode in
				NSAnimationContext.beginGrouping()
				NSAnimationContext.current.duration = 0.5

				switch statusCode {
					case 2001:
						self.usernameErrorLabel.stringValue = "User nicht gefunden"
						self.usernameErrorLabel.animator().isHidden = false
					case 2002:
						self.passwordErrorLabel.stringValue = "Password falsch"
						self.passwordErrorLabel.animator().isHidden = false
					case 2011:
						self.generalErrorLabel.stringValue = "Account gesperrt. Bitte an den QuoJob-Verantwortlichen wenden."
						self.generalErrorLabel.animator().isHidden = false
					case 1000:
						self.generalErrorLabel.stringValue = "Dein QuoJob-Account ist nicht für die API freigeschaltet. Bitte wende dich an den QuoJob-Verantwortlichen."
						self.generalErrorLabel.animator().isHidden = false
					default:
						self.generalErrorLabel.stringValue = "Fehler: \(statusCode)"
						self.generalErrorLabel.animator().isHidden = false
				}

				NSAnimationContext.endGrouping()
			}
		)
	}

	@IBAction func cancel(_ sender: NSButton) {
		dismiss(self)
	}

}
