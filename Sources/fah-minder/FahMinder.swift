//
//  FahMinder.swift
//  fah-minder
//
//  Copyright (c) 2022-2023 Kevin Bernhagen. All rights reserved.
//

import Foundation
import ArgumentParser

struct FahMinder: ParsableCommand {
  static var configuration = CommandConfiguration(
    commandName: Globals.processName,
    abstract: "macOS utility for the folding@home client version 8",
    discussion: "",
    version: Globals.version,
    subcommands: [Start.self, Stop.self,
                  Pause.self, Unpause.self, Finish.self,
                  Status.self, Log.self,
                  Config.self, App.self],
    helpNames: [.long]
  )

  @Flag(name: .shortAndLong)
  var verbose: Int

  //@Argument(help: "host[:port][/group]  use \".\" for localhost")
  //var hostPortPeer: String
  @OptionGroup var options: RemoteCommandOptions

  mutating func validate() throws {
    // can access vars here; validate() is called before subcommand validate
    Globals.verbose = verbose > 0
    Globals.verbosity = verbose
    //Globals.hostPortPeer = hostPortPeer
    Globals.host = options.host
    Globals.port = options.port
    Globals.peer = options.peer
  }

  struct Start: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Start service client.",
      discussion: "<user> must match UserName in client launchd plist.")
    @OptionGroup var options: LocalCommandOptions
    mutating func run() throws {
      try runLocal(command: "start", options: options)
    }
  }

  struct Stop: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Stop all local clients running as <user>.")
    @OptionGroup var options: LocalCommandOptions
    mutating func run() throws {
      try runLocal(command: "stop", options: options)
    }
  }

  struct Pause: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Send pause to client.")
    mutating func run() throws {
      try runRemote(command: "pause")
    }
  }

  struct Unpause: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Send unpause to client.")
    mutating func run() throws {
      try runRemote(command: "unpause")
    }
  }

  struct Finish: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Send finish to client; cleared by pause/unpause.")
    mutating func run() throws {
      try runRemote(command: "finish")
    }
  }

  // TODO: print a more readable format than raw JSON, esp for units
  // TODO: convert message text/data to Dictionary/Array
  struct Status: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Show client units, config, info.")

    mutating func run() throws {
      let client = FahClient(host: Globals.host, port: Globals.port, peer: Globals.peer)
      client.verbosity = Globals.verbosity
      client.onDidReceive = { event in
        switch event {
        case .text(let string):
          print(string)
          CFRunLoopStop(CFRunLoopGetMain())
        case .error, .disconnected, .cancelled:
          CFRunLoopStop(CFRunLoopGetMain())
        default:
          break
        }
      }
      client.connect()
      CFRunLoopRun()
    }
  }

  struct Log: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Show client log. Use control-c to stop.")

    mutating func run() throws {
      let client = FahClient(host: Globals.host, port: Globals.port)
      let filter = ":\(Globals.peer):"
      client.verbosity = Globals.verbosity
      client.onDidReceive = { event in
        switch event {
        case .connected(_):
          client.send(["cmd": "log", "enable": true]) {}
        case .text(let string):
          // FIXME: this works, but is obviously deficient
          if let data = string.data(using: .utf8) {
            let result = try? JSONSerialization.jsonObject(with:data, options: [])
            if let arr = result as? [Any] {
              if arr[0] as? String == "log" {
                if let line = arr[2] as? String {
                  if filter == "::" || line.contains(filter) { print(line) }
                }
              }
            }
          }
        case .error, .disconnected(_,_), .cancelled:
          // FIXME: not sufficient to catch ws close by client
          // get eventual error:
          // The operation couldn’t be completed. (Network.NWError error 0.)
          CFRunLoopStop(CFRunLoopGetMain())
        default:
          break
        }
      }
      client.connect()
      CFRunLoopRun()
    }
  }

  struct Config: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Set client config values.",
      subcommands: [Cause.self, Checkpoint.self, Cpus.self, FoldAnon.self,
        Key.self, OnIdle.self, Passkey.self, Priority.self, Team.self,
        User.self])

    struct Cpus: ParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Set client config cpus.")

      @Argument(help: "Number of cpus, max 256, further limited by client.")
      var value: UInt

      mutating func validate() throws {
        if value > 256 {
          throw ValidationError("Maximum cpus value is 256.")
        }
      }

      mutating func run() throws {
        send(config: ["cpus": value])
      }
    }

    struct Cause: ParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Set client config cause preference.")

      @Argument(help: "any, alzheimers, cancer, huntingtons, parkinsons, influenza, diabetes, covid-19")
      var value: Causes

      mutating func run() throws {
        send(config: ["cause": value.rawValue])
      }
    }

    struct Checkpoint: ParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Set client config checkpoint.")

      @Argument(help: "3 to 30")
      var value: Int

      mutating func validate() throws {
        let range = 3...30
        if !range.contains(value) {
          throw ValidationError("checkpoint must be in range 3 to 30.")
        }
      }

      mutating func run() throws {
        send(config: ["checkpoint": value])
      }
    }

    struct FoldAnon: ParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Set client config fold-anon.",
        discussion: "Fold without a username, team or passkey.")

      @Argument(help: "true, false, yes, no, 1, 0")
      var value: String

      mutating func validate() throws {
        try validateBoolString(value)
      }

      mutating func run() throws {
        send(config: ["fold_anon": value.bool!])
      }
    }

    struct Key: ParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Set client config key.")

      @Argument(help: "use 0 unless given a key")
      var value: UInt64

      mutating func run() throws {
        send(config: ["key": value])
      }
    }

    struct OnIdle: ParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Set client config on-idle.",
        discussion: "Only fold when computer is idle.")

      @Argument(help: "true, false, yes, no, 1, 0")
      var value: String

      mutating func validate() throws {
        try validateBoolString(value)
      }

      mutating func run() throws {
        send(config: ["on_idle": value.bool!])
      }
    }

    struct Passkey: ParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Set client config passkey.")

      @Argument(help: "empty string or 32 hexadecimal characters")
      var value: String

      mutating func validate() throws {
        let re = #"^[0-9a-f]{32}$"#
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if value == "" { return }
        value = value.lowercased()
        guard value.range(of: re, options: .regularExpression) != nil else {
          throw ValidationError("passkey must be empty string or 32 hex chars")
        }
      }

      mutating func run() throws {
        send(config: ["passkey": value])
      }
    }

    struct Priority: ParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Set client config priority preference.")

      @Argument(help: "idle, low, normal, inherit, high")
      var value: ProcessPriority

      mutating func run() throws {
        send(config: ["priority": value.rawValue])
      }
    }

    struct Team: ParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Set client config team.")

      @Argument(help: "An existing team number 0 to 2147483647")
      var value: Int32

      mutating func validate() throws {
        let range = 0...Int32.max
        if !range.contains(value) {
          throw ValidationError("team must be in range  0 to 2147483647.")
        }
      }

      mutating func run() throws {
        send(config: ["team": value])
      }
    }

    struct User: ParsableCommand {
      static var configuration = CommandConfiguration(
        abstract: "Set client config user.")

      @Argument(help: "max 100 bytes and no tab, newline, return chars")
      var value: String

      mutating func validate() throws {
        let re = #"^[^\t\n\r]{1,100}$"#
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if value == "" {
          value = "Anonymous"
          return
        }
        let m = "user must be 100 bytes max and not contain tab, newline, return chars."
        if value.utf8.count > 100 {
          throw ValidationError(m)
        }
        guard value.range(of: re, options: .regularExpression) != nil else {
          throw ValidationError(m)
        }
      }

      mutating func run() throws {
        send(config: ["user": value])
      }
    }

  }

  struct App: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "app",
      abstract: "Run interactive terminal app.",
      discussion: "NOT IMPLEMENTED",
      shouldDisplay: false)

    mutating func run() throws {
      print("NOT IMPLEMENTED")
    }
  }
}


extension FahMinder.Config {

  enum Causes: String, ExpressibleByArgument, CaseIterable {
    // https://api.foldingathome.org/project/cause
    case any // "unspecified"
    case alzheimers
    case cancer
    case huntingtons
    case parkinsons
    case influenza
    case diabetes
    case covid_19 = "covid-19"
  }

  enum ProcessPriority: String, ExpressibleByArgument, CaseIterable {
    case idle
    case low
    case normal
    case inherit
    case high
  }

  static func send(config: [String:Any]) {
    let client = FahClient(host: Globals.host, port: Globals.port, peer: Globals.peer)
    client.verbosity = Globals.verbosity
    client.onDidReceive = { event in
      switch event {
      case .connected(_):
        client.send(config: config) {
          CFRunLoopStop(CFRunLoopGetMain())
        }
      case .error, .disconnected, .cancelled:
        CFRunLoopStop(CFRunLoopGetMain())
      default:
        break
      }
    }
    client.connect()
    CFRunLoopRun()
  }

  static func validateBoolString(_ value: String) throws {
    guard value.bool != nil else {
      throw ValidationError("\"\(value)\" is not true, false, yes, no, 1, 0.")
    }
  }
}


extension FahMinder {

  static func runLocal(command: String, options: LocalCommandOptions) throws {
    let knownCommands = ["start", "stop"]
    if knownCommands.contains(command) {
      let note = "\(Globals.notifyPrefix).\(options.user).\(command)"
      if Globals.verbose { print("posting \"\(note)\"") }
      notifyPost(name: note)
      // TODO: if stop, optionally wait for user's fah-client to exit
      // could open websocket and wait for disconnect
    } else {
      throw MyError.unknownCommand(command)
    }
  }

  static func runRemote(command: String) throws {
    let knownCommands = ["pause", "unpause", "finish"]
    if knownCommands.contains(command) {
      let client = FahClient(host: Globals.host, port: Globals.port, peer: Globals.peer)
      client.verbosity = Globals.verbosity
      client.onDidReceive = { event in
        switch event {
        case .connected(_):
          client.send(command: command) {
            CFRunLoopStop(CFRunLoopGetMain())
          }
        case .error, .disconnected, .cancelled:
          CFRunLoopStop(CFRunLoopGetMain())
        default:
          break
        }
      }
      client.connect()
      CFRunLoopRun()
    } else {
      throw MyError.unknownCommand(command)
    }
  }

  mutating func run() throws {
    print(FahMinder.helpMessage())
    print(Globals.examplesText)
  }
}
