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

		view.wantsLayer = true
		view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

		generalErrorLabel.isHidden = true
		usernameErrorLabel.isHidden = true
		passwordErrorLabel.isHidden = true
	}

	private func loginSuccess() {
		let name = usernameTextField.stringValue
		let pass = passwordTextField.stringValue

		if (storeInKeyChain.state == .on) {
			keychain = Keychain(service: KEYCHAIN_NAMESPACE)
			keychain[name] = pass
		}

		if (CoreDataHelper.jobs().count == 0) {
			GlobalNotification.shared.deliverNotification(
				withTitle: "Initiale Daten werden geladen.",
				andInformationtext: "Dies kann bis zu einer Minute dauern, aber ich sage Bescheid, wenn ich fertig bin 😉"
			)

			QuoJob.shared.syncData().catch({ _ in })
		} else {
			GlobalNotification.shared.deliverNotification(withTitle: "Erfolgreich eingeloggt.")
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

		QuoJob.shared.loginWithUserData(userName: name, password: pass)
			.done {
				self.loginSuccess()
			}.catch { error in
				NSAnimationContext.beginGrouping()
				NSAnimationContext.current.duration = 0.5
				self.generalErrorLabel.stringValue = error.localizedDescription
				self.generalErrorLabel.animator().isHidden = false
				NSAnimationContext.endGrouping()
			}
	}

}
