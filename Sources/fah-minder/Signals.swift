//
//  Signals.swift
//  fah-minder
//
//  Copyright (c) 2022 Kevin Bernhagen. All rights reserved.
//

import Foundation

private struct Signal {
  static let names: [UnsafePointer<Int8>?] = makeArray(from: sys_signame)
  static func name(_ sig: Int32) -> String {
    if sig < 0 || sig >= NSIG { return "" }
    if let name = Signal.names[Int(sig)] {
      return String(cString: name)
    } else { return "" }
  }
}

// must keep strong references
private var signalSources = [DispatchSourceSignal]()

func registerExitSignal(_ sig: Int32) {
  if sig < 1 || sig >= NSIG { return }
  signal(sig, SIG_IGN)
  let source = DispatchSource.makeSignalSource(signal: sig)
  source.setEventHandler {
    if Globals.verbose {
      let name = Signal.name(sig)
      let desc = String(cString:strsignal(sig))
      print("Got signal \(name): \(desc)")
    }
    CFRunLoopStop(CFRunLoopGetMain())
    // watchdog
    DispatchQueue.global().async {
      sleep(10)
      exit(1)
    }
  }
  source.resume()
  signalSources.append(source)
}
