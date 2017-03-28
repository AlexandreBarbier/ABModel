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
                          "fourth": 4.0 as AnyObject]
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

        let object = StringModel(dictionary:stringBaseDico)

        XCTAssert(object.first == "one")
        XCTAssert(object.second == "two")
        XCTAssert(object.third == "three")
        XCTAssert(object.fourth == 4)
    }

    func testDescription() {
        let object = StringModel(dictionary:stringBaseDico)

        XCTAssert("\(object.toJSON())" == object.description)
    }

    func testWrong() {
        ABModel.debug = true
        let object = WrongModel(dictionary: ["uninitialisedArray": [stringBaseDico, stringBaseDico] as AnyObject,
                                             "replaceMe": "OK" as AnyObject, "strTest": "test" as AnyObject,
                                             "strTest2": "test" as AnyObject])
        XCTAssert(object.replaced == "OK")
        XCTAssert(object.strTest == "test")

        ABModel.debug = false
        let object2 = WrongModel(dictionary: ["uninitialisedArray": [stringBaseDico, stringBaseDico] as AnyObject,
                                             "replaceMe": "OK" as AnyObject, "strTest": "test" as AnyObject,
                                             "strTest2": "test" as AnyObject])
        XCTAssert(object2.replaced == "OK")
        XCTAssert(object2.strTest == "test")
    }

    func testError() {
        let object = WrongModel(dictionary: ["uninitialisedArray": [stringBaseDico, stringBaseDico] as AnyObject,
                                             "replaceMe": "OK" as AnyObject])
        XCTAssert(object.replaced == "OK")
    }

    func testCoder() {
        let object = StringModel(dictionary:stringBaseDico)

        let data = NSKeyedArchiver.archivedData(withRootObject: object)
        let _: UserDefaults = {
            $0.set(data, forKey:"test")
            $0.synchronize()
            return $0
        } (UserDefaults.standard)
        if let dataObject = UserDefaults.standard.value(forKey: "test") as? Data {
            if let codedObject = NSKeyedUnarchiver.unarchiveObject(with: dataObject) as? StringModel {
                XCTAssert(codedObject.first == "one")
                XCTAssert(codedObject.second == "two")
                XCTAssert(codedObject.third == "three")
                XCTAssert(codedObject.fourth == 4)
            }
        } else {
            XCTFail()
        }
    }

    func testPrint() {
        let object = StringModel(dictionary:stringBaseDico)
        let k = object.toJSON()
        for (key, value) in stringBaseDico {
            if let val = value as? String, let jsVal = k[key] as? String {
                XCTAssert(jsVal == val)
            }
        }
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
        var complexeObj = ComplexModel(dictionary:complexObjDico)
        for _ in 0..<10 {
            complexeObj = ComplexModel(dictionary:complexObjDico)
        }
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

    func testSimpleParsing() {
        let baseDico = ["array": arrayBaseDico as AnyObject,
                        "str": stringBaseDico as AnyObject]
        let hugeDico = Array(repeating: baseDico, count: 1000)
        var resultArray: [CustomTypeModel] = []
        measure {
            resultArray.removeAll()
            for dico in hugeDico {
                resultArray.append(CustomTypeModel(with: dico))
            }
        }

        XCTAssert(resultArray.count == 1000)
    }
}
