//
//  Schema.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public func Schema(_ dictionary: [Dict.Key:_Schema],
                   ignoreExtraKeys: Bool = false) -> Dict
{
  return Dict(dictionary, ignoreExtraKeys: ignoreExtraKeys)
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

public class Use<DI, DO>: _Schema, Validator {

  private let schema: (DI) throws -> DO

  public init(_ schema: @escaping (DI) throws -> DO) {
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
      return try schema(data)
    } catch {
      throw SchemaError("schema failed to validate.", error)
    }
  }

}

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

public final class Type<D>: _Schema, Validator {

  public init(_ type: D.Type) { }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? D else {
      throw SchemaError("type mismatch, expected a `\(D.self)`.")
    }

    let result = try validate(dataʹ)

    return result as Any

  }

  public func validate(_ data: D) throws -> D {
    return data
  }

}

public final class Dict: _Schema, ExpressibleByDictionaryLiteral, Validator {

  private let schema: [Key:_Schema]
  private var ignoreExtraKeys: Bool = false

  public init(_ dictionary: [Key:_Schema], ignoreExtraKeys: Bool = false) {
    schema = dictionary
    self.ignoreExtraKeys = ignoreExtraKeys
  }

  public init(dictionaryLiteral: (Key, _Schema)...) {
    schema = Dictionary<Key, _Schema>(uniqueKeysWithValues: dictionaryLiteral)
  }

  private func keyValidatorPair(for key: String) -> (Key, _Schema)? {
    guard let keyʹ = schema.keys.first(where: {$0.key == key}) else { return nil }
    return (keyʹ, schema[keyʹ]!)
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? DataIn else {
      throw SchemaError("type mismatch, expected a `[String:Any]` value.")
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
      guard unexpected.count > 0 else { fatalError("no unexpected keys in collection") }
      if unexpected.count == 1 {
        throw SchemaError("unexpected key '\(unexpected.first!)'.")
      } else {
        throw SchemaError("unexpected keys \(unexpected.map({"'\($0)'"}).joined(separator: ", "))")
      }
    }

    for key in resolved {

      do {
        switch key {
        case .forbidden:
          var possibleResult: Any? = nil
          do {
            possibleResult = try schema[key]!.validate(data[key.key]!)
            possibleResult = nil
            throw SchemaError("possitive match for forbidden key '\(key.key)'")
          } catch {
            if let possibleResult = possibleResult { result[key.key] = possibleResult }
            else { throw error }
          }
        default:
          result[key.key] = try schema[key]!.validate(data[key.key]!)
        }

      } catch {
        throw SchemaError("validation failed for key '\(key.key)'.", error)
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

public final class Or<V1, V2>: _Schema, Validator
  where V1:Validator, V2:Validator, V1.DataIn == V2.DataIn, V1.DataOut == V2.DataOut
{

  private let validator1: V1
  private let validator2: V2

  public init(_ validator1: V1, _ validator2: V2) {
    self.validator1 = validator1
    self.validator2 = validator2
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? V1.DataIn else {
      throw SchemaError("type mismatch, expected a `\(V1.DataIn.self)` value.")
    }

    return try validate(dataʹ)

  }

  public func validate(_ data: V1.DataIn) throws -> V1.DataOut {

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

public final class And<V1, V2>: _Schema, Validator
  where V1:Validator, V2:Validator, V1.DataOut == V2.DataIn
{

  private let validator1: V1
  private let validator2: V2

  public init(_ validator1: V1, _ validator2: V2) {
    self.validator1 = validator1
    self.validator2 = validator2
  }

  public override func validate(_ data: Any) throws -> Any {

    guard let dataʹ = data as? V1.DataIn else {
      throw SchemaError("type mismatch, expected a `\(V1.DataIn.self)` value.")
    }

    return try validate(dataʹ)

  }

  public func validate(_ data: V1.DataIn) throws -> V2.DataOut {

    let intermediateData: V1.DataOut

    do {
      intermediateData = try validator1.validate(data)
    } catch {
      throw SchemaError("the first predicate failed to validate", error)
    }

    do {
      return try validator2.validate(intermediateData)
    } catch {
      throw SchemaError("the second predicate failed to validate", error)
    }

  }

}

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

public struct SchemaError: Error, CustomStringConvertible {

  private let _localizedDescription: String

  public var localizedDescription: String {
    guard !underlyingErrors.isEmpty else { return _localizedDescription }
    var result = _localizedDescription
    result.append(" (")
    let underlyingDescriptions = underlyingErrors.map({$0.localizedDescription})
    result.append(underlyingDescriptions.joined(separator: ", "))
    result.append(")")
    return result
  }

  public let underlyingErrors: [Error]

  public init(_ localizedDescription: String, _ underlyingErrors: Error...) {
    _localizedDescription = localizedDescription
    self.underlyingErrors = underlyingErrors
  }

  public var description: String {
    return localizedDescription
  }

}



prefix operator >> // Use
prefix operator ∈  // Type
prefix operator ∀  // Pred
prefix operator ⊆  // List
prefix operator ⊨  // Dict
prefix operator ~/ // Regex


public prefix func >><T,U>(block: @escaping (T) throws -> U) -> Use<T,U> {
  return Use<T,U>(block)
}

public func &&<V1, V2>(lhs: V1, rhs: V2) -> And<V1, V2> where V1:Validator, V2:Validator {
  return And<V1, V2>(lhs, rhs)
}

public func ||<V1, V2>(lhs: V1, rhs: V2) -> Or<V1, V2> where V1:Validator, V2:Validator {
  return Or<V1, V2>(lhs, rhs)
}

public prefix func ∈<D>(type: D.Type) -> Type<D> {
  return Type<D>(type)
}

public prefix func ∀<D>(predicate: @escaping (D) throws -> Bool) -> Pred<D> {
  return Pred<D>(predicate)
}

public prefix func ⊆<D:Hashable, S:Sequence>(list: S) -> List<D> where S.Element == D {
  return List<D>(list)
}

public prefix func ⊨(dictionary: [Dict.Key:_Schema]) -> Dict {
  return Dict(dictionary)
}

public prefix func ⊨(tuple: ([Dict.Key:_Schema], Bool)) -> Dict {
  return Dict(tuple.0, ignoreExtraKeys: tuple.1)
}

public prefix func ~/(pattern: String) -> Regex {
  return Regex(pattern)
}
