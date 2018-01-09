//
//  Type.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public final class Type<D>: _Schema, Validator {

  public init(_ type: D.Type) { }

  public override func validate(_ data: Any) throws -> Any {

    if let dataʹ = data as? D {
      return dataʹ
    } else if data is String,
              D.self is Int.Type,
              let dataʹ = data as? String,
              let i = Int(dataʹ) as? D
    {
      return i
    } else if data is String,
              D.self is Float.Type,
              let dataʹ = data as? String,
              let f = Float(dataʹ) as? D
    {
      return f
    } else if data is String,
              D.self is Double.Type,
              let dataʹ = data as? String,
              let d = Double(dataʹ) as? D
    {
      return d
    } else if data is CustomStringConvertible,
              D.self is String.Type,
              let dataʹ = data as? CustomStringConvertible,
              let s = dataʹ.description as? D
    {
      return s
    } else if data is String, D.self is Bool.Type, let dataʹ = data as? String {
      let dataʺ: Bool
      switch dataʹ {
        case "t", "T", "true", "True", "TRUE", "yes", "Yes", "YES", "y", "Y": dataʺ = true
        default: dataʺ = false
      }
      if let data = dataʺ as? D { return data }
    }


    throw SchemaError("""
      type mismatch, expected a `\(D.self)` value or something convertible to a `\(D.self)` value.
      """)

  }

  public func validate(_ data: D) throws -> D {
    return data
  }

}

