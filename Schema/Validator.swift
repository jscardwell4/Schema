//
//  Validator.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public protocol Validator {

  associatedtype DataIn
  associatedtype DataOut

  func validate(_ data: DataIn) throws -> DataOut
  func validate(_ data: Any) throws -> Any

}

