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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testStringParsing() {
        let dico = ["first": "one" as AnyObject, "second": "two" as AnyObject, "third": "three" as AnyObject]
        let object = StringModel(dictionary: dico)
        XCTAssert(object.first == "one")
        XCTAssert(object.second == "two")
        XCTAssert(object.third == "three")
    }
    
    func testArrayParsing() {
        let dico = ["stringArray": ["one", "two", "three"] as AnyObject, "intArray": [1,2,3] as AnyObject, "floatArray":[Float(1.0),Float(1.99)] as AnyObject]
        let object = ArrayModel(dictionary: dico)
        XCTAssert(object.stringArray!.first == "one")
        XCTAssert(object.intArray!.first == 1)
        XCTAssert(object.floatArray!.first == Float(1.0))
    }
    
    func testArrayParsing() {
        let dico = ["stringArray": ["one", "two", "three"] as AnyObject, "intArray": [1,2,3] as AnyObject, "floatArray":[Float(1.0),Float(1.99)] as AnyObject]
        let object = ArrayModel(dictionary: dico)
        XCTAssert(object.stringArray!.first == "one")
        XCTAssert(object.intArray!.first == 1)
        XCTAssert(object.floatArray!.first == Float(1.0))
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        
    }
}
