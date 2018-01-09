//
//  Operators.swift
//  Schema
//
//  Created by Jason Cardwell on 1/8/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import Foundation

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
  return Dict(tuple.0, ignoreExtras: tuple.1)
}

public prefix func ~/(pattern: String) -> Regex {
  return Regex(pattern)
}
