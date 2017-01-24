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



    init(with str: [String: AnyObject]) {
        super.init()
        if let fi = str["first"] as? String {
            self.first = fi
        }
        if let fi = str["second"] as? String {
            self.second = fi
        }
        if let fi = str["third"] as? String {
            self.third = fi
        }
        if let fi = str["fourth"] as? NSNumber {
            self.fourth = fi.floatValue
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(dictionary: [String : AnyObject]) {
        super.init(dictionary: dictionary)
    }
}

class ArrayModel: ABModel {
    var stringArray: [String]?
    var intArray: [Int]?
    var floatArray: [Float]?


    init(with str: [String: AnyObject]) {
        super.init()
        if let fi = str["stringArray"] as? [String] {
            self.stringArray = fi
        }
        if let fi = str["intArray"] as? [Int] {
            self.intArray = fi
        }
        if let fi = str["floatArray"] as? [Float] {
            self.floatArray = fi
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(dictionary: [String : AnyObject]) {
        super.init(dictionary: dictionary)
    }
}

class CustomTypeModel: ABModel {
    var array: ArrayModel?
    var str: StringModel?

    init(with str: [String: AnyObject]) {
        super.init()
        if let fi = str["array"] as? [String: AnyObject] {
            self.array = ArrayModel(with: fi)
        }
        if let fi = str["str"] as? [String: AnyObject] {
            self.str = StringModel(with: fi)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(dictionary: [String : AnyObject]) {
        super.init(dictionary: dictionary)
    }

    override init() {
        super.init()
    }
}

class ComplexModel: ABModel {
    var customArray: [CustomTypeModel] = [CustomTypeModel()]
    var str: String?
    var stM: StringModel?
    var arr: ArrayModel?

    init(with str: [String: AnyObject]) {
        super.init()
        if let fi = str["customArray"] as? [[String: AnyObject]] {
           self.customArray = fi.map({ (dico) -> CustomTypeModel in
            CustomTypeModel(with: dico)
            })

        }
        if let fi = str["str"] as? String {
            self.str = fi
        }
        if let fi = str["stM"] as? [String: AnyObject] {
            self.stM = StringModel(with: fi)
        }
        if let fi = str["arr"] as? [String: AnyObject] {
            self.arr = ArrayModel(with: fi)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(dictionary: [String : AnyObject]) {
        super.init(dictionary: dictionary)
    }

}
