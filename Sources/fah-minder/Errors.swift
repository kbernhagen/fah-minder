//
//  Errors.swift
//  fah-minder
//
//  Copyright (c) 2022 Kevin Bernhagen. All rights reserved.
//

import Foundation

enum MyError: Error {
  case generalError(_ string: String)
  case unknownCommand(_ string: String)

  var description: String {
    switch self {
    case .generalError(let string):
      return "Error: \(string)"
    case .unknownCommand(let string):
      return "Error: Unknown command: \"\(string)\""
    }
  }
}
