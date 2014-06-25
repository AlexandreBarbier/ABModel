//
//  ABModel.swift
//  ABModel
//
//  Created by Alexandre Barbier on 24/06/14.
//  Copyright (c) 2014 abarbier. All rights reserved.
//

import UIKit

/**
* IMPROVEMENT : I have to find a way to parse custom typed array from this class in order to avoid overriding 
*               setValue(value: AnyObject!, forKey key: String!) in each subclass
*/


/**
*
* You just need to inherit from this class to be able to create object from JSON 
* You have to name your properties like the JSON keys or override the method replaceKey to rename a JSON key
*
*/
class ABModel: NSObject, Printable {
    
    override var description :String
    {
        get
        {
            return "ABModel super class you should override this method"
        }
    }
    
    init() {
        super.init()
    }
    
    init(dictionary:Dictionary<String, AnyObject>) {
        super.init()
        var finalDictionnary = dictionary
        for (key, value : AnyObject) in dictionary {
            if !self.respondsToSelector(Selector(key)) {
                var replacementKey = self.replaceKey(key)
                if replacementKey.isEmpty {
                    finalDictionnary.removeAtIndex(finalDictionnary.indexForKey(key)!)
                    
                }
                else {
                    finalDictionnary[replacementKey] = value;
                    finalDictionnary.removeAtIndex(finalDictionnary.indexForKey(key)!)
                    
                }
            }
        }
        self.setValuesForKeysWithDictionary(finalDictionnary)
    }
    
    override func setValue(value: AnyObject!, forKey key: String!)  {
        
        /**
        * here we want to check the type of the property named key to know if it's an array / dictionnary.
        * if it's an array / dictionnary we have to know the objects type contain in it to make something smart
        * if we can't find a solution here we just have to override setValue in each subclass and apply the correct treatment 
        * for nested properties
        */
        //here we check if the value is nil to avoid crash
        if (value != nil) {
            super.setValue(value, forKey: key)
        }
        
    }
    
    /**
    * You should override this method only if you want to rename JSON key
    */
    func replaceKey(key:String) -> String {
        return "";
    }
}
