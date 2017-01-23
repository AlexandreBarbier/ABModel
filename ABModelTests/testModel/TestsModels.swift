//
//  StringModel.swift
//  ABModel
//
//  Created by Alexandre barbier on 10/11/2016.
//  Copyright © 2016 abarbier. All rights reserved.
//

import UIKit
import ABModel

class StringModel: ABModel {
    var first: String?
    var second: String?
    var third: String?
    var fourth: Float = 0
}

class ArrayModel: ABModel {
    var stringArray: [String]?
    var intArray: [Int]?
    var floatArray: [Float]?
}

class CustomTypeModel: ABModel {
    var array: ArrayModel?
    var str: StringModel?
}

class ComplexModel: ABModel {
    var customArray: [CustomTypeModel] = [CustomTypeModel()]
    var str: String?
    var stM: StringModel?
    var arr: ArrayModel?
}
