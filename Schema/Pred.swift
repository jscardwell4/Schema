//
//  Pred.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public final class Pred<D>: _Schema, Validator {

  public typealias DataIn = D
  public typealias DataOut = D

  private let isValid: (D) throws -> Bool

  public init(_ isValid: @escaping (D) throws -> Bool) {
    self.isValid = isValid
    super.init()
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? D else {
      throw SchemaError("type mismatch, expected a `\(D.self)` value.")
    }

    let result = try validate(dataʹ)

    return result as Any

  }

  public func validate(_ data: D) throws -> D {
    do {
      guard try isValid(data) else {
        throw SchemaError("predicate failed to validate")
      }
      return data
    } catch {
      throw error
    }

  }


}

