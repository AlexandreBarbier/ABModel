//
//  NSDataJSON.swift
//  ABModel
//
//  Created by Alexandre barbier on 10/05/15.
//  Copyright (c) 2015 abarbier. All rights reserved.
//

import UIKit

public extension NSData {
    func toJSON() -> Dictionary<String, AnyObject> {
        do {
            if let data = try NSJSONSerialization.JSONObjectWithData(self, options: NSJSONReadingOptions.MutableLeaves) as? Dictionary<String, AnyObject> {
                return data
            }
            return [:]
        }
        catch {
            return [:]
        }
    }
}
