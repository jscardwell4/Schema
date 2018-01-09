//
//  Or.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public final class Or<V1, V2>: _Schema, Validator where V1:Validator, V2:Validator {

  private let validator1: V1
  private let validator2: V2

  public init(_ validator1: V1, _ validator2: V2) {
    self.validator1 = validator1
    self.validator2 = validator2
  }

  public override func validate(_ data: Any) throws -> Any {
    do {
      return try validator1.validate(data)
    } catch let error1 {
      do {
        return try validator2.validate(data)
      } catch let error2 {
        throw SchemaError("both predicates failed to validate.", error1, error2)
      }
    }

  }

}

