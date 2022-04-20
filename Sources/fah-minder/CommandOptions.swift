//
//  CommandOptions.swift
//  fah-minder
//
//  Copyright (c) 2022 Kevin Bernhagen. All rights reserved.
//

import Foundation
import ArgumentParser

struct LocalCommandOptions: ParsableArguments {
  @Flag(name: .shortAndLong)
  var verbose = false

  @Option(name: .shortAndLong,
    help: "The user account running the local client.")
  var user: String = Globals.defaultUser
}

struct RemoteCommandOptions: ParsableArguments {
  @Flag(name: .shortAndLong)
  var verbose = false

  // TODO: support optional :port on host
  @Option(name: .shortAndLong, help: "The host running a client.")
  var host: String = Globals.defaultHost

  @Option(name: .shortAndLong, help: "The client websocket port.")
  var port: Int = Globals.defaultPort
}
