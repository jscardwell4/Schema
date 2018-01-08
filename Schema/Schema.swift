//
//  Schema.swift
//  Schema
//
//  Created by Jason Cardwell on 1/7/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public func Schema(_ dictionary: [Dictionary.Key:_Schema],
                   ignoreExtraKeys: Bool = false) -> Dictionary
{
  return Dictionary(dictionary, ignoreExtraKeys: ignoreExtraKeys)
}

public func Schema<Data:Hashable>(_ list: [Data]) -> Member<Data> {
  return Member(list)
}

public func Schema<Data>(_ block: @escaping (Data) throws -> Bool) -> Callable<Data> {
  return Callable(block)
}

public func Schema<Data>(_ keyPath: KeyPath<Data,Bool>) -> Callable<Data> {
  return Callable({$0[keyPath: keyPath]})
}

public class _Schema {

  fileprivate init() {}

  public func validate(_ data: Any) throws -> Any {
    fatalError("must be overriden by subclasses")
  }

}

public protocol Validator {

  associatedtype DataIn
  associatedtype DataOut

  func validate(_ data: DataIn) throws -> DataOut
  func validate(_ data: Any) throws -> Any

}

public class Use<DataIn, DataOut>: _Schema, Validator {

  private let schema: (DataIn) throws -> DataOut

  public init(_ schema: @escaping (DataIn) throws -> DataOut) {
    self.schema = schema
    super.init()
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? DataIn else {
      throw SchemaError("type mismatch, expected \(DataIn.self).")
    }

    let result = try validate(dataʹ)

    return result as Any

  }

  public func validate(_ data: DataIn) throws -> DataOut {
    do {
      return try schema(data)
    } catch {
      throw SchemaError("Use: schema failed to validate.", error)
    }
  }

}

public final class Constant<Data, Dataʹ>: _Schema, Validator {

  private let schema: Use<Data, Dataʹ>

  public init(_ schema: @escaping (Data) throws -> Dataʹ) {
    self.schema = Use(schema)
    super.init()
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? DataIn else {
      throw SchemaError("type mismatch, expected \(DataIn.self).")
    }

    let result = try validate(dataʹ)

    return result as Any

  }

  public func validate(_ data: Data) throws -> Data {
    do {
      _ = try schema.validate(data) as Dataʹ
      return data
    } catch {
      throw SchemaError("Constant: schema failed to validate.", error)
    }
  }

}

public final class Boolean: _Schema, Validator, ExpressibleByBooleanLiteral {

  public let isValid: Bool

  public init(_ isValid: Bool) { self.isValid = isValid }

  public override func validate(_ data: Any) throws -> Any {
    guard isValid else {
      throw SchemaError("Boolean: `isValid` has been set to `false`.")
    }
    return data
  }

  public convenience init(booleanLiteral value: Bool) {
    self.init(value)
  }

}

public final class Callable<Data>: _Schema, Validator {

  public typealias DataIn = Data
  public typealias DataOut = Data

  private let isValid: (Data) throws -> Bool

  public init(_ isValid: @escaping (Data) throws -> Bool) {
    self.isValid = isValid
    super.init()
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? DataIn else {
      throw SchemaError("type mismatch, expected \(DataIn.self).")
    }

    let result = try validate(dataʹ)

    return result as Any

  }

  public func validate(_ data: Data) throws -> Data {
    do {
      guard try isValid(data) else {
        throw SchemaError("Callable: invalid data")
      }
      return data
    } catch {
      throw SchemaError("Callable: failed to validate data.", error)
    }

  }


}

public final class Type<Data>: _Schema, Validator {

  public init(_ type: Data.Type) { }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? DataIn else {
      throw SchemaError("type mismatch, expected \(DataIn.self).")
    }

    let result = try validate(dataʹ)

    return result as Any

  }

  public func validate(_ data: Data) throws -> Data {
    return data
  }

}

public final class Dictionary: _Schema, ExpressibleByDictionaryLiteral, Validator {

  private let schema: [Key:_Schema]
  private var ignoreExtraKeys: Bool = false

  public init(_ dictionary: [Key:_Schema], ignoreExtraKeys: Bool = false) {
    schema = dictionary
    self.ignoreExtraKeys = ignoreExtraKeys
  }

  public init(dictionaryLiteral: (Key, _Schema)...) {
    schema = Swift.Dictionary<Key, _Schema>(uniqueKeysWithValues: dictionaryLiteral)
  }

  private func keyValidatorPair(for key: String) -> (Key, _Schema)? {
    guard let keyʹ = schema.keys.first(where: {$0.key == key}) else { return nil }
    return (keyʹ, schema[keyʹ]!)
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? DataIn else {
      throw SchemaError("type mismatch, expected \(DataIn.self).")
    }

    let result = try validate(dataʹ)

    return result as Any

  }

  public func validate(_ data: [String:Any]) throws -> [String:Any] {

    var result: [String:Any] = [:]

    let providedKeys = Set(data.keys)

    var resolved: Set<Key> = []

    for key in schema.keys {
      if providedKeys.contains(key.key) { resolved.insert(key) }
      else if key.isRequired { throw SchemaError("Dictionary: missing key '\(key.key)'") }
    }

    guard providedKeys.count <= resolved.count || ignoreExtraKeys else {
      let unexpected = providedKeys.subtracting(resolved.map({$0.key}))
      throw SchemaError("Dictionary: unexpected keys: \(unexpected.joined(separator: ", "))")
    }

    for key in resolved {

      do {
        result[key.key] = try schema[key]!.validate(data[key.key]!)
      } catch {
        throw SchemaError("Dictionary: validation failed for key '\(key.key)'")
      }

    }

    return result

  }

  public enum Key: Hashable, ExpressibleByStringLiteral {

    case optional (String, AnyHashable?)
    case forbidden (String)
    case string (String)

    public var key: String {
      switch self {
      case .optional(let value, _): return value
      case .forbidden(let value): return value
      case .string(let value): return value
      }
    }

    public init(stringLiteral value: String) {
      self = .string(value)
    }
    
    public var isRequired: Bool {
      switch self {
        case .string: return true
        default: return false
      }
    }

    public static func ==(lhs: Key, rhs: Key) -> Bool {
      return lhs.hashValue == rhs.hashValue
    }

    public var hashValue: Int {
      switch self {
      case .optional(let key, let defaultValue):
        return key.hashValue ^ (defaultValue?.hashValue ?? 0)
      case .forbidden(let key), .string(let key):
        return key.hashValue
      }
    }

  }
}

public final class Member<Data:Hashable>: _Schema, Validator, ExpressibleByArrayLiteral {

  public typealias DataIn = Data
  public typealias DataOut = Data

  private let list: Set<Data>

  public init<S>(_ list: S) where S:Sequence, S.Element == Data {
    self.list = Set(list)
    super.init()
  }

  public convenience init(arrayLiteral elements: Data...) {
    self.init(elements)
  }

  public override func validate(_ data: Any) throws -> Any {

    if let dataʹ = data as? Data {
      return try validate(dataʹ) as Any
    } else if let dataʹ = data as? [Data] {
      return try validate(dataʹ) as Any
    } else {
      throw SchemaError("type mismatch, expected \(Data.self) or \([Data].self).")
    }

  }

  public func validate(_ data: Data) throws -> Data {

    guard list.contains(data) else {
      throw SchemaError("expected `data` to be one of \(list)")
    }

    return data

  }

  public func validate(_ data: [Data]) throws -> [Data] {

    guard list.isSuperset(of: data) else {
      throw SchemaError("expected `data` to be composed of \(list)")
    }

    return data

  }
}

public final class Or<DataIn, DataOut, Validator1, Validator2>: _Schema, Validator
  where Validator1:Validator, Validator1.DataIn == DataIn, Validator1.DataOut == DataOut,
        Validator2:Validator, Validator2.DataIn == DataIn, Validator2.DataOut == DataOut
{

  private let validator1: Validator1
  private let validator2: Validator2

  public init(_ validator1: Validator1, _ validator2: Validator2) {
    self.validator1 = validator1
    self.validator2 = validator2
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? DataIn else {
      throw SchemaError("type mismatch, expected \(DataIn.self).")
    }

    let result = try validate(dataʹ)

    return result as Any

  }

  public func validate(_ data: DataIn) throws -> DataOut {

    do {
      return try validator1.validate(data)
    } catch let error1 {
      do {
        return try validator2.validate(data)
      } catch let error2 {
        throw SchemaError("Or: neither branch could validate the data provided.", error1, error2)
      }

    }

  }

}

public final class And<DataIn, DataIntermediate, DataOut, Validator1, Validator2>: _Schema, Validator
  where Validator1:Validator, Validator1.DataIn == DataIn, Validator1.DataOut == DataIntermediate,
        Validator2:Validator, Validator2.DataIn == DataIntermediate, Validator2.DataOut == DataOut
{

  private let validator1: Validator1
  private let validator2: Validator2

  public init(_ validator1: Validator1, _ validator2: Validator2) {
    self.validator1 = validator1
    self.validator2 = validator2
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? DataIn else {
      throw SchemaError("type mismatch, expected \(DataIn.self).")
    }

    let result = try validate(dataʹ)

    return result as Any

  }

  public func validate(_ data: DataIn) throws -> DataOut {

    let intermediateData: DataIntermediate

    do {
      intermediateData = try validator1.validate(data)
    } catch {
      throw SchemaError("And: the first predicate failed to validate", error)
    }

    do {
      return try validator2.validate(intermediateData)
    } catch {
      throw SchemaError("And: the second predicate failed to validate", error)
    }

  }

}

public final class RegularExpression: _Schema, Validator, ExpressibleByStringLiteral {

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

    guard let dataʹ = data as? DataIn else {
      throw SchemaError("type mismatch, expected \(DataIn.self).")
    }

    let result = try validate(dataʹ)

    return result as Any

  }

  public func validate(_ data: String) throws -> String {

    if regex == nil {
      do {
        regex = try NSRegularExpression(pattern: pattern, options: [])
      } catch {
        throw SchemaError("RegularExpression: pattern failed to comile.", error)
      }
    }

    let matchCount = regex!.numberOfMatches(in: data,
                                            range: NSRange(location: 0,
                                                           length: data.utf16.count))
    guard matchCount > 0 else {
      throw SchemaError("RegularExpression: data does not match the specified pattern.")
    }

    return data

  }

}

public struct SchemaError: Error {

  private let _localizedDescription: String

  public var localizedDescription: String {
    guard !underlyingErrors.isEmpty else { return _localizedDescription }
    var result = _localizedDescription
    result.append(" ")
    let underlyingDescriptions = underlyingErrors.map({$0.localizedDescription})
    result.append(underlyingDescriptions.joined(separator: ", "))
    return result
  }

  public let underlyingErrors: [Error]

  public init(_ localizedDescription: String, _ underlyingErrors: Error...) {
    _localizedDescription = localizedDescription
    self.underlyingErrors = underlyingErrors
  }


}

