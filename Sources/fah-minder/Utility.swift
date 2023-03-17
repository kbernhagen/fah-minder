//
//  Utility.swift
//  fah-minder
//
//  Copyright (c) 2022-2023 Kevin Bernhagen. All rights reserved.
//

import Foundation

func makeVersionString() -> String {
  // return something like git describe --always --dirty
  var version = VCS_TAG ?? "0.0.0"
  // tag[-tick-gshorthash][-modified]
  if let tick = VCS_TICK {
    if tick != 0 || VCS_WC_MODIFIED {
      version += "-\(tick)-g\(VCS_SHORT_HASH)"
    }
  }
  if VCS_WC_MODIFIED {
    version += "-modified"
  }
  return version
}

func notifyPost(name: String!) {
  let nc = CFNotificationCenterGetDarwinNotifyCenter()
  let nn = CFNotificationName(name as CFString)
  CFNotificationCenterPostNotification(nc, nn, nil, nil, true)
}

extension String {
  var bool: Bool? {
    switch self.lowercased() {
    case "true", "yes", "1":
      return true
    case "false", "no", "0":
      return false
    default:
      return nil
    }
  }
}

func jsonString(_ obj: Any?) -> String? {
  guard let obj = obj else { return nil }
  var jsonData: Data?
  if #available(macOS 10.15, *) {
    jsonData = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys, .fragmentsAllowed, .prettyPrinted, .withoutEscapingSlashes])
  } else {
    jsonData = try? JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys, .fragmentsAllowed, .prettyPrinted])
  }
  if jsonData == nil { return nil }
  return String(data: jsonData!, encoding: .utf8)
}
