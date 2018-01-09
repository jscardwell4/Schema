//
//  SchemaTests.swift
//  SchemaTests
//
//  Created by Jason Cardwell on 1/6/18.
//  Copyright © 2018 Moondeer Studios. All rights reserved.
//
import XCTest
@testable import Schema

prefix operator >> // Use
prefix operator ∈  // Type
prefix operator ∀  // Pred
prefix operator ⊆  // List
prefix operator ⊨  // Dict
prefix operator ~/ // Regex


final class SchemaTests: XCTestCase {


  func testSchema() {

    let schema1 = Schema(\Double.isFinite)

    XCTAssertNoThrow(try schema1.validate(4.6))
    XCTAssertThrowsError(try schema1.validate(.infinity))
    XCTAssertEqual(try? schema1.validate(4.6), 4.6)


    let schema2 = Schema({(data: Int) in data > 0})

    XCTAssertNoThrow(try schema2.validate(26))
    XCTAssertThrowsError(try schema2.validate(-2))
    XCTAssertEqual(try? schema2.validate(26), 26)


  }

  func testUse() {

    let use1 = Use<String,Int>({
      guard let int = Int($0) else { throw SchemaError("Failed to convert string to int") }
      return int
    })

    XCTAssertNoThrow(try use1.validate("123"))
    XCTAssertThrowsError(try use1.validate("fail"))
    XCTAssertEqual(try? use1.validate("123"), 123)

    let use2 = Use<Int,String>({
      guard $0 > 0 else { throw SchemaError("must be greater than zero.") }
      return $0.description
    })

    XCTAssertNoThrow(try use2.validate(123))
    XCTAssertThrowsError(try use2.validate(-123))
    XCTAssertEqual(try? use2.validate(123), "123")

    let use3 = >>{(i:Int) -> String in i.description}
    XCTAssertNoThrow(try use3.validate(123))
    XCTAssertThrowsError(try use3.validate("123"))
    XCTAssertEqual(try? use3.validate(123), "123")

    enum StringEnum: String {
      case zero, one, two, three, four
    }

    let use4 = Use<String, StringEnum>(StringEnum.init(rawValue:))
    XCTAssertNoThrow(try use4.validate("two"))
    XCTAssertThrowsError(try use4.validate(2))
    XCTAssertThrowsError(try use4.validate("five"))
    XCTAssertEqual(try? use4.validate("four"), StringEnum.four)

  }

  func testOr() {

    let or1 = Or(Schema({(data: Int) in data > 10}), Schema({(data: Int) in data < -10}))
    XCTAssertNoThrow(try or1.validate(123))
    XCTAssertThrowsError(try or1.validate(5))
    XCTAssertEqual((try? or1.validate(123)) as? Int, 123)


    let or2 = ∀({(data: Int) in data > 10}) || ∀({(data: Int) in data < -10})
    XCTAssertNoThrow(try or2.validate(123))
    XCTAssertThrowsError(try or2.validate(5))
    XCTAssertEqual((try? or2.validate(123)) as? Int, 123)

  }

  func testAnd() {

    let and1 = And(Schema({(data: Int) in data > 10}), Schema({(data: Int) in data % 2 == 0}))
    XCTAssertNoThrow(try and1.validate(120))
    XCTAssertThrowsError(try and1.validate(5))
    XCTAssertThrowsError(try and1.validate(121))
    XCTAssertEqual((try? and1.validate(124)) as? Int, 124)

    let and2 = ∀({(data: Int) in data > 10}) && ∀({(data: Int) in data % 2 == 0})
    XCTAssertNoThrow(try and2.validate(120))
    XCTAssertThrowsError(try and2.validate(5))
    XCTAssertThrowsError(try and2.validate(121))
    XCTAssertEqual((try? and2.validate(124)) as? Int, 124)

  }

  func testDict() {

    let dict1: Schema.Dict = [
      "name": Type(String.self),
      "age": Schema({(data: Int) in data >= 18 && data <= 99})
    ]

    struct NotConvertible {}

    XCTAssertNoThrow(try dict1.validate(["name": "Sue", "age": 28]))
    XCTAssertThrowsError(try dict1.validate(["name": "Sue", "age": 8]))
    XCTAssertThrowsError(try dict1.validate(["name": NotConvertible(), "age": 28]))

    let result1 = try? dict1.validate(["name": "Sue", "age": 28])
    XCTAssertEqual(result1?["name"] as? String, "Sue")
    XCTAssertEqual(result1?["age"] as? Int, 28)

    let dict2 = ⊨[
      "name": Type(String.self),
      "age": Schema({(data: Int) in data >= 18 && data <= 99})
    ]

    XCTAssertNoThrow(try dict2.validate(["name": "Sue", "age": 28]))
    XCTAssertThrowsError(try dict2.validate(["name": "Sue", "age": 8]))
    XCTAssertThrowsError(try dict2.validate(["name": NotConvertible(), "age": 28]))

    let result2 = try? dict2.validate(["name": "Sue", "age": 28])
    XCTAssertEqual(result2?["name"] as? String, "Sue")
    XCTAssertEqual(result2?["age"] as? Int, 28)

  }

  func testRegex() {

    let regex1: Regex = "^[a-z ]+$"
    XCTAssertNoThrow(try regex1.validate("not gonna do it"))
    XCTAssertThrowsError(try regex1.validate("gonna_do_it"))
    XCTAssertEqual(try regex1.validate("farts"), "farts")

    let regex2 = ~/"^[a-z ]+$"
    XCTAssertNoThrow(try regex2.validate("not gonna do it"))
    XCTAssertThrowsError(try regex2.validate("gonna_do_it"))
    XCTAssertEqual(try regex2.validate("farts"), "farts")

  }

  func testList() {

    let list1 = List([1, 2, 3, 4])
    XCTAssertNoThrow(try list1.validate(3))
    XCTAssertThrowsError(try list1.validate(7))
    XCTAssertEqual(try list1.validate(2), 2)
    XCTAssertNoThrow(try list1.validate([4, 3, 1, 2]))
    XCTAssertThrowsError(try list1.validate([7, 2, 3]))
    XCTAssertEqual(try list1.validate([1, 2, 3]), [1, 2, 3])

    let list2 = ⊆[1, 2, 3, 4]
    XCTAssertNoThrow(try list2.validate(3))
    XCTAssertThrowsError(try list2.validate(7))
    XCTAssertEqual(try list2.validate(2), 2)
    XCTAssertNoThrow(try list2.validate([4, 3, 1, 2]))
    XCTAssertThrowsError(try list2.validate([7, 2, 3]))
    XCTAssertEqual(try list2.validate([1, 2, 3]), [1, 2, 3])

  }


  func testType() {

    let type1 = Type(Int.self)
    XCTAssertNoThrow(try type1.validate(4))
    XCTAssertNoThrow(try type1.validate("4"))
    XCTAssertThrowsError(try type1.validate("rew4"))
    XCTAssertEqual(try type1.validate(4), 4)
    XCTAssertEqual(try type1.validate("4") as? Int, 4)

    let type2 = ∈Int.self
    XCTAssertNoThrow(try type2.validate(4))
    XCTAssertNoThrow(try type2.validate("4"))
    XCTAssertThrowsError(try type2.validate("Zd4"))
    XCTAssertEqual(try type2.validate(4), 4)
    XCTAssertEqual(try type2.validate("4") as? Int, 4)

    struct NotConvertible {}

    let type3 = Type(String.self)
    XCTAssertNoThrow(try type3.validate(4))
    XCTAssertNoThrow(try type3.validate("4"))
    XCTAssertThrowsError(try type3.validate(NotConvertible()))
    XCTAssertEqual(try type3.validate(4) as? String, "4")
    XCTAssertEqual(try type3.validate("4"), "4")

    let type4 = ∈String.self
    XCTAssertNoThrow(try type4.validate(4))
    XCTAssertNoThrow(try type4.validate("4"))
    XCTAssertThrowsError(try type4.validate(NotConvertible()))
    XCTAssertEqual(try type4.validate(4) as? String, "4")
    XCTAssertEqual(try type4.validate("4"), "4")

  }

}
