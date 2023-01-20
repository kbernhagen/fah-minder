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

  // If declared here, it will steal from subcommands that want it
  //@Flag var verbose = false

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
    @OptionGroup var options: RemoteCommandOptions
    mutating func run() throws {
      try runRemote(command: "pause", options: options)
    }
  }

  struct Unpause: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Send unpause to client.")
    @OptionGroup var options: RemoteCommandOptions
    mutating func run() throws {
      try runRemote(command: "unpause", options: options)
    }
  }

  struct Finish: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Send finish to client; cleared by pause/unpause.")
    @OptionGroup var options: RemoteCommandOptions
    mutating func run() throws {
      try runRemote(command: "finish", options: options)
    }
  }

  // TODO: print a more readable format than raw JSON, esp for units
  // TODO: convert message text/data to Dictionary/Array
  struct Status: ParsableCommand {
    static var configuration = CommandConfiguration(
      abstract: "Show client units, config, info.")
    @OptionGroup var options: RemoteCommandOptions

    mutating func run() throws {
      let client = FahClient(host: options.host, port: options.port, peer: options.peer)
      client.verbose = options.verbose
      client.onDidReceive = { event in
        switch event {
        case .text(let string):
          print(string)
          CFRunLoopStop(CFRunLoopGetMain())
        case .error, .disconnected:
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
    @OptionGroup var options: RemoteCommandOptions

    mutating func run() throws {
      Globals.verbose = options.verbose > 1
      let client = FahClient(host: options.host, port: options.port)
      let filter = ":\(options.peer):"
      client.verbose = options.verbose
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
        case .error, .disconnected:
          CFRunLoopStop(CFRunLoopGetMain())
        default:
          break
        }
      }
      client.connect()
      CFRunLoopRun()
    }
  }

  // config [key] [value]
  struct Config: ParsableCommand {
    // FIXME should have subcommand for each key
    static var configuration = CommandConfiguration(
      abstract: "Show or set client config values.",
      discussion: "NOT IMPLEMENTED",
      shouldDisplay: false)

    @OptionGroup var options: RemoteCommandOptions
    @Argument var key: String = ""
    @Argument var value: String = ""

    mutating func run() throws {
      print("NOT IMPLEMENTED")
    }
  }

  struct App: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "app",
      abstract: "Run interactive terminal app.",
      discussion: "NOT IMPLEMENTED",
      shouldDisplay: false)

    @OptionGroup var options: RemoteCommandOptions

    mutating func run() throws {
      print("NOT IMPLEMENTED")
    }
  }
}


extension FahMinder {

  static func runLocal(command: String, options: LocalCommandOptions) throws {
    let knownCommands = ["start", "stop"]
    if knownCommands.contains(command) {
      let note = "\(Globals.notifyPrefix).\(options.user).\(command)"
      if options.verbose > 0 { print("posting \"\(note)\"") }
      notifyPost(name: note)
      // TODO: if stop, optionally wait for user's fah-client to exit
      // could open websocket and wait for disconnect
    } else {
      throw MyError.unknownCommand(command)
    }
  }

  static func runRemote(command: String, options: RemoteCommandOptions) throws {
    let knownCommands = ["pause", "unpause", "finish"]
    if knownCommands.contains(command) {
      let client = FahClient(host: options.host, port: options.port, peer: options.peer)
      client.verbose = options.verbose
      client.onDidReceive = { event in
        switch event {
        case .connected(_):
          client.send(command: command) {
            CFRunLoopStop(CFRunLoopGetMain())
          }
        case .error, .disconnected:
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
