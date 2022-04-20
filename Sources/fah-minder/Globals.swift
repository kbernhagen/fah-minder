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
  static let defaultPort = 7396
  static let defaultUser = "nobody"
  static let notifyPrefix = "org.foldingathome.fahclient"
  static var verbose = false
  static let examplesText = """

  EXAMPLES:
    \(processName) status --host other.local
  
    # ssh tunnel to host "other.local"
    ssh -f -L 8101:localhost:7396 me@other.local sleep 2 \\
      && \(processName) status -p 8101
  
  NOTES:
    The client may not support IPv6 addresses.
    By default, the client only listens for connections from localhost.
    To send commands to remote clients, you must set config.xml
    http-addresses to 0.0.0.0:7396 and restart the client. Note that this
    will allow anyone on the local network to mess with your client.
    Not recommended, especially for laptops.
    You might want to use the ssh tunnel instead.
  
  """
}
