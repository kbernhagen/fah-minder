//
//  main.swift
//  fah-minder
//
//  Copyright (c) 2022 Kevin Bernhagen. All rights reserved.
//

import Foundation

registerExitSignal(SIGINT)
registerExitSignal(SIGTERM)
signal(SIGPIPE, SIG_IGN)
signal(SIGHUP, SIG_IGN)

FahMinder.main()
