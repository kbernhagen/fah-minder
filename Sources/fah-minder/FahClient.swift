//
//  FahClient.swift
//  fah-minder
//
//  Copyright (c) 2022 Kevin Bernhagen. All rights reserved.
//

import Foundation
import Starscream

public class FahClient: WebSocketDelegate {
  var name: String?
  let host: String
  let port: Int
  var shouldExitOnError = true
  var verbose = false
  var isConnected = false
  private var socket: WebSocket?
  private var cache: [String:Any]
  var lastError: Error?
  public var onDidReceive: (_ event: WebSocketEvent) -> Void
  private var timeoutTimer: DispatchSourceTimer?

  // send(config: [String:Any]),
  // processMessage, processUpdate

  init(name: String? = nil, host: String, port: Int) {
    self.name = name
    self.host = host
    self.port = port
    cache = [String:Any]()
    if name == nil { self.name = "\(host):\(port)" }
    onDidReceive = {_ in}
  }

  func connect() {
    if isConnected { return }
    cache.removeAll()
    let urlString = "ws://\(host):\(port)/api/websocket"
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
      if self.shouldExitOnError {
        exit(1)
        //CFRunLoopStop(CFRunLoopGetMain())
      }
    }
    timeoutTimer?.resume()
    socket?.connect()
  }

  func disconnect() {
    timeoutTimer?.cancel()
    timeoutTimer = nil
    socket?.disconnect()
    socket = nil
  }

  func proccessMessage(_ msg: String) {
    
  }
  func proccessMessage(_ msg: Data) {
    
  }

  public func didReceive(event: WebSocketEvent, client: WebSocket) {
    switch event {
    case .connected(let headers):
      isConnected = true
      if verbose {
        print("websocket is connected: \(headers)")
      }
      timeoutTimer?.cancel()
      timeoutTimer = nil
    case .disconnected(let reason, let code):
      isConnected = false
      if verbose {
        print("websocket is disconnected: \(reason) with code: \(code)")
      }
    case .text(let string):
      if verbose {
        print("Received text: \(string)")
      }
      proccessMessage(string)
    case .binary(let data):
      if verbose {
        print("Received data: \(data.count)")
      }
      proccessMessage(data)
    case .ping(_):
      if verbose {
        print("Received ping")
      }
      break
    case .pong(_):
      if verbose {
        print("Received pong")
      }
      break
    case .viabilityChanged(let flag):
      if verbose {
        print("viabilityChanged \(flag)")
      }
      break
    case .reconnectSuggested(let flag):
      if verbose {
        print("reconnectSuggested \(flag)")
      }
      break
    case .cancelled:
      isConnected = false
      if verbose {
        print("websocket cancelled")
      }
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
    if shouldExitOnError { exit(1) }
  }

  func send(command: String, completion: (() -> ())?) {
    let knownCommands = ["pause", "unpause", "finish"]
    if knownCommands.contains(command) {
      if verbose { print("Sending command \(command)") }
      let cmd = "{\"cmd\": \"\(command)\"}" // JSON
      socket?.write(string: cmd, completion: completion)
    }
  }

  func send(_ msg: String, completion: (() -> ())?) {
    // assume valid JSON string to send
    socket?.write(string: msg, completion: completion)
  }
}
