//
//  Dict.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

public final class Dict: _Schema, ExpressibleByDictionaryLiteral, Validator {

  private let schema: [Key:_Schema]
  private var ignoreExtras: Bool = false

  public init(_ dictionary: [Key:_Schema], ignoreExtras: Bool = false) {
    schema = dictionary
    self.ignoreExtras = ignoreExtras
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

    guard providedKeys.count <= resolved.count || ignoreExtras else {
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

    public func hash(into hasher: inout Hasher) {
      switch self {
        case .optional(let key, let defaultValue):
          key.hash(into: &hasher)
          (defaultValue ?? 0 as AnyHashable).hash(into: &hasher)
        case .forbidden(let key), .string(let key):
          key.hash(into: &hasher)
      }
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

