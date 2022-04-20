//
//  Utility.swift
//  fah-minder
//
//  Copyright (c) 2022 Kevin Bernhagen. All rights reserved.
//

import Foundation

func makeVersionString() -> String {
  // return something like git describe --always --dirty
  var version = VCS_TAG ?? "0.0.0"
  // tag[-tick-gshorthash][-dirty]
  if let tick = VCS_TICK {
    version += "-\(tick)-g\(VCS_SHORT_HASH)"
  }
  if VCS_WC_MODIFIED {
    version += "-dirty"
  }
  return version
}

func notifyPost(name: String!) {
  let nc = CFNotificationCenterGetDarwinNotifyCenter()
  let nn = CFNotificationName(name as CFString)
  CFNotificationCenterPostNotification(nc, nn, nil, nil, true)
}
