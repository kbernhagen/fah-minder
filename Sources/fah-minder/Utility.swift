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

extension NSObject {
  // FIXME: This is a hack to prevent an objc exception in value(forKeyPath:)
  // when a key does not exist on a leaf object.
  // compiler no longer allows this
  //@objc func value(forUndefinedKey key: String) -> Any? { return nil }
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

func jsonString(_ obj: Any?, pretty: Bool = true) -> String? {
  guard let obj = obj else { return nil }
  var jsonData: Data?
  var opt: JSONSerialization.WritingOptions
  if #available(macOS 10.15, *) {
    if pretty {
      opt = [.sortedKeys, .fragmentsAllowed, .prettyPrinted, .withoutEscapingSlashes]
    } else {
      opt = [.sortedKeys, .fragmentsAllowed, .withoutEscapingSlashes]
    }
  } else {
    if pretty {
      opt = [.sortedKeys, .fragmentsAllowed, .prettyPrinted]
    } else {
      opt = [.sortedKeys, .fragmentsAllowed]
    }
  }
  jsonData = try? JSONSerialization.data(withJSONObject: obj, options: opt)
  if jsonData == nil { return nil }
  return String(data: jsonData!, encoding: .utf8)
}

func dropPrivileges() {
  var gid = getgid()
  var uid = getuid()
  // if root, use SUDO_UID else -2 "nobody"
  if uid == 0 || gid == 0 {
    let env = ProcessInfo.processInfo.environment
    let suid = UInt32(env["SUDO_UID"] ?? "0")!
    let sgid = UInt32(env["SUDO_GID"] ?? "0")!
    if uid == 0 {
      if suid != 0 { uid = suid }
      else { uid = UInt32.max - 1 }
    }
    if gid == 0 {
      if sgid != 0 { gid = sgid }
      else { gid = UInt32.max - 1 }
    }
  }
  // TODO: error checking
  setgid(gid)
  setregid(gid, gid)
  setuid(uid)
  setreuid(uid, uid)
}
