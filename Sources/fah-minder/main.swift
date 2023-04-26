//
//  main.swift
//  fah-minder
//
//  Copyright (c) 2022-2023 Kevin Bernhagen. All rights reserved.
//

import Darwin

dropPrivileges()

registerExitSignal(SIGINT)
registerExitSignal(SIGTERM)
signal(SIGPIPE, SIG_IGN)
signal(SIGHUP, SIG_IGN)

if CommandLine.arguments.count == 1 {
  FahMinder.usage()
  exit(EX_USAGE)
}

if CommandLine.arguments[1] == "help" {
  // insert required peer argument so help works
  CommandLine.arguments.insert(".", at: 1)
}

if CommandLine.arguments.count == 3 && CommandLine.arguments[2] == "help" {
  FahMinder.usage()
} else {
  FahMinder.main()
}
