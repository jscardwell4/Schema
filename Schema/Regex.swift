//
//  Regex.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public final class Regex: _Schema, Validator, ExpressibleByStringLiteral {

  public typealias StringLiteralType = String

  private var regex: NSRegularExpression? = nil

  public let pattern: String

  public init(_ pattern: String) {
    self.pattern = pattern
    super.init()
  }

  public convenience init(stringLiteral value: String) {
    self.init(value)
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? String else {
      throw SchemaError("type mismatch, expected a `String` value.")
    }

    return try validate(dataʹ)

  }

  public func validate(_ data: String) throws -> String {

    if regex == nil {
      do {
        regex = try NSRegularExpression(pattern: pattern, options: [])
      } catch {
        throw SchemaError("pattern '\(pattern)' failed to comile.", error)
      }
    }

    let matchCount = regex!.numberOfMatches(in: data,
                                            range: NSRange(location: 0,
                                                           length: data.utf16.count))
    guard matchCount > 0 else {
      throw SchemaError("'\(data)' does not match pattern '\(pattern)'")
    }

    return data

  }

}

