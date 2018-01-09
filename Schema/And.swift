//
//  And.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public final class And<V1, V2>: _Schema, Validator where V1:Validator, V2:Validator {

  private let validator1: V1
  private let validator2: V2

  public init(_ validator1: V1, _ validator2: V2) {
    self.validator1 = validator1
    self.validator2 = validator2
  }

  public override func validate(_ data: Any) throws -> Any {
    return try validator2.validate(try validator1.validate(data))
  }

}

