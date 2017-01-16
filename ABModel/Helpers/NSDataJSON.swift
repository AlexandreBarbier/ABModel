//
//  NSDataJSON.swift
//  ABModel
//
//  Created by Alexandre barbier on 10/05/15.
//  Copyright (c) 2015 abarbier. All rights reserved.
//

import UIKit

public extension Data {
    func toJSON() -> [String: AnyObject] {
        do {
            if let data = try JSONSerialization.jsonObject(with: self,
                                                           options: JSONSerialization.ReadingOptions.mutableLeaves)
                as? [String: AnyObject] {
                return data
            }
            return [:]
        } catch {
            return [:]
        }
    }
}
