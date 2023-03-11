//
//  CommandOptions.swift
//  fah-minder
//
//  Copyright (c) 2022-2023 Kevin Bernhagen. All rights reserved.
//

import Foundation
import ArgumentParser

struct LocalCommandOptions: ParsableArguments {
  @Flag(name: .shortAndLong)
  var verbose: Int

  @Option(name: .shortAndLong,
    help: "The user account running the local client.")
  var user: String = Globals.defaultUser

  // TODO: possibly validate user against local users and aliases
}

struct RemoteCommandOptions: ParsableArguments {
  @Flag(name: .shortAndLong)
  var verbose: Int

  // TODO: support optional :port on host
  @Option(name: .shortAndLong, help: "The host running a client.")
  var host: String = Globals.defaultHost

  @Option(name: .shortAndLong, help: "The client websocket port.")
  var port: UInt16 = Globals.defaultPort

  @Option(name: .long, help: "Case sensitive peer name starting with \"/\".")
  var peer: String = ""

  mutating func validate() throws {
    // fah-web-client-bastet util.js
    //let _peerRE = #"^(([\w.-]+)(:\d+)?)?(\/[\w.-]+)?$"# // [host[:port]][/rg]
    // https://wiert.me/2017/08/29/regex-regular-expression-to-match-dns-hostname-or-ip-address-stack-overflow/
    // https://en.wikipedia.org/wiki/Hostname
    // does not allow unicode
    let hostRE = #"^([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])(\.([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]{0,61}[a-zA-Z0-9]))*\.?$"#
    //let hostRE = #"^[\w][\w.-]*$"# // no :port, no IPv6, allow underscore utf8
    var maxLength = 253 // bytes
    if host.hasSuffix(".") { maxLength = 254 }
    guard host.count <= maxLength else {
      throw ValidationError("Maximum length of host is 253 ascii characters, plus an optional period.")
    }
    guard host.range(of: hostRE, options: .regularExpression) != nil else {
      throw ValidationError("Host must consist of letters, numbers, period, hyphen.")
    }

    guard port > 0 else {
      throw ValidationError("Please specify a 'port' number greater than 0.")
    }

    if peer != "" {
      let peerRE = #"^\/[\w.-]*$"# // allow invalid "/" for now
      guard peer.range(of: peerRE, options: .regularExpression) != nil else {
        throw ValidationError("Peer must have prefix \"/\" and consist of letters, numbers, period, hyphen, underscore.")
      }
    }
  }
}
