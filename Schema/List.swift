//
//  List.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public final class List<D:Hashable>: _Schema, Validator, ExpressibleByArrayLiteral {

  public typealias DataIn = D
  public typealias DataOut = D

  private let list: Set<D>

  public init<S>(_ list: S) where S:Sequence, S.Element == D {
    self.list = Set(list)
    super.init()
  }

  public convenience init(arrayLiteral elements: D...) {
    self.init(elements)
  }

  public override func validate(_ data: Any) throws -> Any {

    if let dataʹ = data as? D {
      return try validate(dataʹ)
    } else if let dataʹ = data as? [D] {
      return try validate(dataʹ)
    } else {
      throw SchemaError("type mismatch, expected a `\(D.self)` or `\([D].self)` value.")
    }

  }

  public func validate(_ data: D) throws -> D {

    return try validate([data])[0]

  }

  public func validate(_ data: [D]) throws -> [D] {

    for value in data where !list.contains(value) {
      throw SchemaError("\(value) is not in (\(list.map({"\($0)"}).joined(separator: ", ")))")
    }

    return data

  }
}

