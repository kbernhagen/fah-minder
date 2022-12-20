//
//  Globals.swift
//  fah-minder
//
//  Copyright (c) 2022 Kevin Bernhagen. All rights reserved.
//

import Foundation

struct Globals {
  static let processName = ProcessInfo.processInfo.processName
  static let version = makeVersionString()
  static let defaultHost = "127.0.0.1"
  static let defaultPort: UInt16 = 7396
  static let defaultUser = "nobody"
  static let notifyPrefix = "org.foldingathome.fahclient"
  static var verbose = false
  static let examplesText = """

  EXAMPLE:
    # ssh tunnel to host "other.local"
    ssh -f -L 8101:localhost:7396 me@other.local sleep 2 \\
      && \(processName) status -p 8101
  
  NOTES:
    By default, the client only listens for connections from localhost.

  """
}
