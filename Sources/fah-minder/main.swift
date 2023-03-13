//
//  main.swift
//  fah-minder
//
//  Copyright (c) 2022-2023 Kevin Bernhagen. All rights reserved.
//

import Foundation

registerExitSignal(SIGINT)
registerExitSignal(SIGTERM)
signal(SIGPIPE, SIG_IGN)
signal(SIGHUP, SIG_IGN)

if CommandLine.arguments.count == 1 {
  FahMinder.usage()
} else {
  FahMinder.main()
}
