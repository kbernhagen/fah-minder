//
//  CommandOptions.swift
//  fah-minder
//
//  Copyright (c) 2022-2023 Kevin Bernhagen. All rights reserved.
//

import Foundation
import ArgumentParser

func validate(host: String) throws {
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
}

func validate(group: String) throws {
  if group != "" {
    let gRE = #"^\/[\w.-]*$"# // allow invalid "/" for now
    guard group.range(of: gRE, options: .regularExpression) != nil else {
      throw ValidationError("Group must have prefix \"/\" and consist of letters, numbers, period, hyphen, underscore.")
    }
  }
}


struct LocalCommandOptions: ParsableArguments {
  @Option(name: .shortAndLong,
    help: "The user account running the local client.")
  var user: String = Globals.defaultUser

  // TODO: possibly validate user against local users and aliases
}


struct MainCommandOptions: ParsableArguments {
  @Flag(name: .shortAndLong)
  var verbose: Int
  @Argument(help: "[host][:port][/group]  use \".\" for localhost")
  var peer: String

  mutating func validate() throws {
    Globals.verbose = verbose > 0
    Globals.verbosity = verbose

    let hpg = peer.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let u = URL(string: "//" + hpg) else {
      throw ValidationError("Invalid peer. Use [host][:port][/group] or \".\"")
    }
    var host = u.host ?? Globals.defaultHost
    let port = u.port ?? Int(Globals.defaultPort)
    let group = u.path

    if ["", "."].contains(host) {host = Globals.defaultHost}
    try fah_minder.validate(host: host)
    Globals.host = host

    // validate port
    guard 0 < port && port <= UInt16.max else {
      throw ValidationError("port must be 1 thru \(UInt16.max).")
    }
    Globals.port = port

    try fah_minder.validate(group: group)
    Globals.group = group
  }
}
