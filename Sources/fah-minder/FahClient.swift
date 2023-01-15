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
  let port: UInt16
  let peer: String
  var shouldExitOnError = true
  var verbose = false
  var isConnected = false
  private var socket: WebSocket?
  private var cache: [String:Any]
  var lastError: Error?
  public var onDidReceive: (_ event: WebSocketEvent) -> Void
  private var timeoutTimer: DispatchSourceTimer?
  private var pingTimer: DispatchSourceTimer?

  init(name: String? = nil, host: String, port: UInt16, peer: String = "") {
    self.name = name
    self.host = host
    self.port = port
    self.peer = peer
    cache = [String:Any]()
    if name == nil {
      self.name = "\(host):\(port)"
      if peer.starts(with:"/") {self.name! += "\(peer)"}
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
        if self.verbose { print("Sent ping") }
      }
    }
    pingTimer?.resume()
  }

  func connect() {
    if isConnected { return }
    cache.removeAll()
    var urlString = "ws://\(host):\(port)/api/websocket"
    if peer.starts(with:"/") {urlString += "\(self.peer)"}
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

  func processUpdate(_ up: [String:Any]) {
  }

  func processUpdate(_ up: [Any]) {
  }

  func proccessMessage(_ msg: String) {
  }

  func proccessMessage(_ msg: Data) {
  }

  public func didReceive(event: WebSocketEvent, client: WebSocket) {
    switch event {
    case .connected(let headers):
      isConnected = true
      startPingTimer()
      if verbose { print("websocket is connected: \(headers)") }
      timeoutTimer?.cancel()
      timeoutTimer = nil
    case .disconnected(let reason, let code):
      isConnected = false
      if verbose {
        print("websocket is disconnected: \(reason) with code: \(code)")
      }
    case .text(let string):
      if verbose { print("Received text: \(string)") }
      proccessMessage(string)
    case .binary(let data):
      if verbose { print("Received data: \(data.count)") }
      proccessMessage(data)
    case .ping(_):
      if verbose { print("Received ping") }
      break
    case .pong(_):
      if verbose { print("Received pong") }
      break
    case .viabilityChanged(let flag):
      if verbose { print("viabilityChanged \(flag)") }
      break
    case .reconnectSuggested(let flag):
      if verbose {
        print("reconnectSuggested \(flag)")
      }
      break
    case .cancelled:
      isConnected = false
      if verbose { print("websocket cancelled") }
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
      print("error: value is not a JSON object:", dict)
      return
    }
    guard let jsonData = try? JSONSerialization.data(withJSONObject: dict)
    else { return }
    let jsonString = String(data: jsonData, encoding: String.Encoding.utf8)!
    send(jsonString, completion: completion)
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
    if verbose { print("Sending string: \(msg)") }
    socket?.write(string: msg, completion: completion)
  }
}
