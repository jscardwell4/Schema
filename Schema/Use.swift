//
//  Use.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public class Use<DI, DO>: _Schema, Validator {

  private let schema: (DI) throws -> DO?

  public init(_ schema: @escaping (DI) throws -> DO?) {
    self.schema = schema
    super.init()
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? DI else {
      throw SchemaError("type mismatch, expected a `\(DI.self)` value.")
    }

    let result = try validate(dataʹ)

    return result as Any

  }

  public func validate(_ data: DI) throws -> DO {
    do {
      guard let result = try schema(data) else {
        throw SchemaError("schema result was `nil`")
      }
      return result
    } catch {
      throw SchemaError("schema failed to validate.", error)
    }
  }

}

