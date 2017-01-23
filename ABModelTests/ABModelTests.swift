//
//  ABModelTests.swift
//  ABModelTests
//
//  Created by Alexandre Barbier on 01/09/14.
//  Copyright (c) 2014 abarbier. All rights reserved.
//

import UIKit
import XCTest
import ABModel

class ABModelTests: XCTestCase {
    let stringBaseDico = ["first": "one" as AnyObject,
                          "second": "two" as AnyObject,
                          "third": "three" as AnyObject,
                          "fourth": 4 as AnyObject]
    let arrayBaseDico = ["stringArray": ["one", "two", "three"] as AnyObject,
                         "intArray": [1, 2, 3] as AnyObject,
                         "floatArray": [Float(1.0), Float(1.99)] as AnyObject]

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testStringParsing() {

        let object = StringModel(dictionary: stringBaseDico)

        XCTAssert(object.first == "one")
        XCTAssert(object.second == "two")
        XCTAssert(object.third == "three")
        XCTAssert(object.fourth == 4)
    }

    func testArrayParsing() {

        let object = ArrayModel(dictionary: arrayBaseDico)

        XCTAssert(object.stringArray!.first == "one")
        XCTAssert(object.intArray!.first == 1)
        XCTAssert(object.floatArray!.first == Float(1.0))
    }

    func testCustomParsing() {

        let customBaseDico = ["array": arrayBaseDico as AnyObject,
                              "str": stringBaseDico as AnyObject]
        let object = CustomTypeModel(dictionary: customBaseDico)
        XCTAssert(object.array!.stringArray!.first == "one")
        XCTAssert(object.array!.intArray!.first == 1)
        XCTAssert(object.array!.floatArray!.first == Float(1.0))
        XCTAssert(object.str!.first == "one")
        XCTAssert(object.str!.second == "two")
        XCTAssert(object.str!.third == "three")
    }

    func testComplexeModel() {

        let customBaseDico = ["array": arrayBaseDico as AnyObject,
                              "str": stringBaseDico as AnyObject]
        let complexObjDico = ["customArray": Array(repeating:customBaseDico, count:100) as AnyObject,
                              "stM": stringBaseDico as AnyObject]
        let complexeObj = ComplexModel(dictionary:complexObjDico)

        XCTAssert(complexeObj.customArray.count == 100)
        XCTAssert(complexeObj.customArray.first?.str?.first == "one")
    }

    func testPerformanceExample() {
        let baseDico = ["array": arrayBaseDico as AnyObject,
                        "str": stringBaseDico as AnyObject]
        let hugeDico = Array(repeating: baseDico, count: 1000)
        var resultArray: [CustomTypeModel] = []
        measure {
            resultArray.removeAll()
            for dico in hugeDico {
                resultArray.append(CustomTypeModel(dictionary: dico))
            }
        }

        XCTAssert(resultArray.count == 1000)
    }
}
