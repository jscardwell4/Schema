//
//  Schema.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public func Schema(_ dictionary: [Dict.Key:_Schema],
                   ignoreExtras: Bool = false) -> Dict
{
  return Dict(dictionary, ignoreExtras: ignoreExtras)
}

public func Schema<Data:Hashable>(_ list: [Data]) -> List<Data> {
  return List(list)
}

public func Schema<Data>(_ block: @escaping (Data) throws -> Bool) -> Pred<Data> {
  return Pred(block)
}

public func Schema<Data>(_ keyPath: KeyPath<Data,Bool>) -> Pred<Data> {
  return Pred({$0[keyPath: keyPath]})
}

public class _Schema {

  internal init() {}

  public func validate(_ data: Any) throws -> Any {
    fatalError("must be overriden by subclasses")
  }

}
