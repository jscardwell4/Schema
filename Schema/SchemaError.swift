//
//  SchemaError.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public struct SchemaError: Error, CustomStringConvertible {

  private let message: String

  public var localizedDescription: String {
    guard !underlyingErrors.isEmpty else { return message }
    var result = message
    result.append(" (")
    let underlyingDescriptions = underlyingErrors.map({
      (e:Error) -> String in
      if let eʹ = e as? SchemaError {
        return eʹ.message
      } else {
        return e.localizedDescription
      }
    })
    result.append(underlyingDescriptions.joined(separator: ", "))
    result.append(")")
    return result
  }

  public let underlyingErrors: [Error]

  public init(_ localizedDescription: String, _ underlyingErrors: Error...) {
    message = localizedDescription
    self.underlyingErrors = underlyingErrors
  }

  public var description: String {
    return underlyingErrors.isEmpty ? message : localizedDescription
  }

}


