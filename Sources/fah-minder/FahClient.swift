//
//  FahClient.swift
//  fah-minder
//
//  Copyright (c) 2022-2023 Kevin Bernhagen. All rights reserved.
//

import Foundation
import Starscream

public class FahClient: WebSocketDelegate {
  var name: String?
  let host: String
  let port: Int
  let group: String
  var shouldExitOnError = true
  var verbosity: Int = 0
  var isConnected = false
  private var socket: WebSocket?
  private var cache: [String:Any]
  var lastError: Error?
  public var onDidReceive: (_ event: WebSocketEvent) -> Void
  private var timeoutTimer: DispatchSourceTimer?
  private var pingTimer: DispatchSourceTimer?

  init(name: String? = nil, host: String, port: Int, group: String = "") {
    self.name = name
    self.host = host
    self.port = port
    self.group = group
    cache = [String:Any]()
    if name == nil {
      self.name = "\(host):\(port)"
      if group.starts(with:"/") {self.name! += "\(group)"}
    }
    onDidReceive = {_ in}
  }

  func startPingTimer() {
    pingTimer?.cancel()
    pingTimer = DispatchSource.makeTimerSource()
    pingTimer?.schedule(deadline: .now() + 30.0, repeating: 30.0)
    pingTimer?.setEventHandler() {
      if self.isConnected {
        self.socket?.write(ping: Data())
        if self.verbosity > 4 { print("Sent ping") }
      }
    }
    pingTimer?.resume()
  }

  func connect() {
    if isConnected { return }
    cache.removeAll()
    var urlString = "ws://\(host):\(port)/api/websocket"
    if group.starts(with:"/") {urlString += "\(group)"}
    let url = URL(string: urlString)
    //if url == nil { return }
    var request = URLRequest(url: url!)
    request.timeoutInterval = 30
    socket = WebSocket(request: request)
    socket?.delegate = self
    timeoutTimer?.cancel()
    timeoutTimer = DispatchSource.makeTimerSource()
    timeoutTimer?.schedule(deadline: .now() + 5.0)
    timeoutTimer?.setEventHandler() {
      fputs("Timeout connecting to \(urlString)\n", stderr)
      if self.shouldExitOnError { Darwin.exit(1) }
    }
    timeoutTimer?.resume()
    socket?.connect()
    socket?.respondToPingWithPong = true
  }

  func disconnect() {
    timeoutTimer?.cancel()
    timeoutTimer = nil
    pingTimer?.cancel()
    pingTimer = nil
    socket?.disconnect()
    socket = nil
  }

  func hasInfo() -> Bool {
    return cache["info"] != nil
  }

  func maxCpus() -> UInt? {
    if let info = cache["info"] as? [String:Any],
      let m = info["cpus"] as? UInt {
      return m
    }
    return nil
  }

  func processUpdate(_ up: [String:Any]) {
    cache = up
    if verbosity > 2 { print("did set cache") }
  }

  func processUpdate(_ up: [Any]) {
  /*
// ["units", unitsIndex, key, value]
// ["units", unitsIndex, value]
// ["units", unitsIndex, null] // not same as nil; NSNull?
// ["units", unitsIndex, {}]
// ["log", index?, value]
// ["info", key, value]
// ["config", key, value]

["units", 0, "progress", 0.999064]
["units", 0, "eta", "2.00 secs"]
["units", 0, "state", "DONE"]
["units", 0, null] // this is unit delete?
["units", 0, {     "wu": 256,     "cpus": 16,     "gpus": [],     "state": "ASSIGN"   }]
["units", 0, "paused", false]
["units", 0, "id", "k5g1gRXjKRlHNhNJcINRERHm10SjTi-seg5znhX-xrk"]
["units", 0, "assignment", {     "time": "2022-03-26T05:07:46Z",     "ws": "128.252.203.11",     "port": 443,     "project": 18206,     "deadline": 432000,     "timeout": 172800,     "credit": 2470,     "cpus": 16,     "core": {"type": 168, "url": "https://cores.foldingathome.org/fahcore-a8-osx-64bit-avx2_256-0.0.12.tar.bz2", "sha256": "7e36d0874f5e87ba5b7aeaf66c08afd1ffa6d16fe21877b2b5f3d15a0a8a9f4a"}   }]
["units", 0, "progress", 0.000347]
["units", 0, "frames", 1]

["log", -1, "\u001b[92m01:08:22:D3:Remote::New client from 192.168.42.99:62440\u001b[0m"]

["info", "cpus", 31]
["config", "cause", "any"]
  */
  }

  func proccessMessage(_ msg: String) {
    if let data = msg.data(using: .utf8) {
      let result = try? JSONSerialization.jsonObject(with:data, options: [.mutableContainers])
      if let snap = result as? [String:Any] {
        processUpdate(snap)
      } else if let array = result as? [Any] {
        processUpdate(array)
      }
    }
  }

  func proccessMessage(_ msg: Data) {
    // client should not be sending data
  }

  public func didReceive(event: WebSocketEvent, client: WebSocket) {
    switch event {
    case .connected(_):
      isConnected = true
      //startPingTimer() // disabled; client will ping us
      if verbosity > 1 {
        let url = socket?.request.description ?? ""
        print("connected to \(url)")
      }
      timeoutTimer?.cancel()
      timeoutTimer = nil
    case .disconnected(let reason, let code):
      isConnected = false
      if verbosity > 3 {
        print("websocket is disconnected: \(reason) with code: \(code)")
      }
    case .text(let string):
      if verbosity > 3 { print("Received text: \(string)") }
      proccessMessage(string)
    case .binary(let data):
      if verbosity > 3 { print("Received data: \(data.count)") }
      proccessMessage(data)
    case .ping(_):
      if verbosity > 4 { print("Received ping") }
      break
    case .pong(_):
      if verbosity > 4 { print("Received pong") }
      break
    case .viabilityChanged(let flag):
      if verbosity > 3 { print("viabilityChanged \(flag)") }
      break
    case .reconnectSuggested(let flag):
      if verbosity > 3 {
        print("reconnectSuggested \(flag)")
      }
      break
    case .cancelled:
      isConnected = false
      if verbosity > 3 { print("websocket cancelled") }
    case .error(let error):
      isConnected = false
      handleError(error)
    }
    onDidReceive(event)
  }

  func handleError(_ error: Error?) {
    lastError = error
    let m = "websocket encountered an error"
    if let e = error as? WSError {
      fputs("\(m): \(e.message)\n", stderr)
    } else if let e = error {
      fputs("\(m): \(e.localizedDescription)\n", stderr)
    } else {
      fputs("\(m)\n", stderr)
    }
    if shouldExitOnError { Darwin.exit(1) }
  }

  func send(_ dict: [String:Any],  completion: (() -> ())?) {
    if !JSONSerialization.isValidJSONObject(dict) {
      fputs("error: value is not a JSON object: \(dict)\n", stderr)
      if shouldExitOnError { Darwin.exit(1) }
      return
    }
    if let jsonString = jsonString(dict, pretty: false) {
      send(jsonString, completion: completion)
    }
    // note: not calling completion
  }

  func send(config: [String:Any],  completion: (() -> ())?) {
    send(["cmd": "config", "config": config], completion: completion)
  }

  func send(command: String, completion: (() -> ())?) {
    let knownCommands = ["pause", "unpause", "finish"]
    if knownCommands.contains(command) {
      send(["cmd": command], completion: completion)
    }
  }

  func send(_ msg: String, completion: (() -> ())?) {
    // assume valid JSON string
    if verbosity > 0 { print("Sending string: \(msg)") }
    socket?.write(string: msg, completion: completion)
  }
}
