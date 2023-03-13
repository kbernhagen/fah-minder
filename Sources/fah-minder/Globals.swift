//
//  Globals.swift
//  fah-minder
//
//  Copyright (c) 2022-2023 Kevin Bernhagen. All rights reserved.
//

import Foundation

struct Globals {
  static let processName = ProcessInfo.processInfo.processName
  static let version = makeVersionString()
  static let defaultHost = "127.0.0.1"
  static let defaultPort: Int = 7396
  static let defaultUser = "nobody"
  static let notifyPrefix = "org.foldingathome.fahclient"
  static var verbose = false
  static var verbosity: Int = 0
  static var host = "."
  static var port: Int = 0
  static var group = ""
  static let examplesText = """

  EXAMPLES:
    \(processName) . finish
    \(processName) /my-p-cores config priority normal
    # ssh tunnel to host "other.local"
    ssh -f -L 8101:localhost:7396 me@other.local sleep 2 \\
      && \(processName) :8101 status
  
  NOTES:
    By default, the client only listens for connections from localhost.

  """
}
