//
//  constants.swift
//  MoJob
//
//  Created by Martin Schneider on 06.04.19.
//  Copyright © 2019 Martin Schneider. All rights reserved.
//


#if DEVELOPMENT
	let RESSOURCE_NAME = "MoJob-Dev"
	let CONTAINER_NAME = "de.martingschneider.mojob"
	let API_URL = "https://mojob-test.moccu/index.php?rpc=1"
	let KEYCHAIN_NAMESPACE = "de.mojobapp-dev.login"
#else
	let RESSOURCE_NAME = "MoJob"
	let CONTAINER_NAME = "de.martingschneider.mojob"
	let API_URL = "https://mojob.moccu/index.php?rpc=1"
	let KEYCHAIN_NAMESPACE = "de.mojobapp.login"
#endif
