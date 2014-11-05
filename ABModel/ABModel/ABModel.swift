//
//  ABModel.swift
//  ABModel
//
//  Created by Alexandre Barbier on 23/08/14.
//  Copyright (c) 2014 abarbier. All rights reserved.
//

import UIKit

/**
*
* You just need to inherit from this class to be able to create object from JSON
* You have to name your properties like the JSON keys or override the method replaceKey to rename a JSON key
*
*/

public class ABModel: NSObject, Printable {
    
    public override var description :String
        {
        get
        {
            
            return "ABModel super class you should override this method in \(NSStringFromClass(self.dynamicType))"
        }
    }
    
    public override init() {
        super.init()
    }
    
    public required init(dictionary:Dictionary<String, AnyObject>) {
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
    
    override public func setValue(value: AnyObject!, forKey key: String!)  {
        

        //here we check if the value is nil to avoid crash
        if (value != nil) {
            /**
            * here we want to check the type of the property named key to know if it's an array / dictionnary.
            * for nested properties
            */
            if (value is [AnyObject] && value is Array<Dictionary<String, AnyObject>>) {
                var arrayValue = self.valueForKey(key) as [ABModel]
                if arrayValue.count > 0 {
                    var arrayElementType = arrayValue[0].dynamicType
                    arrayValue.removeAll(keepCapacity: false)
                    for val in value as Array<Dictionary<String, AnyObject>> {
                        var l = arrayElementType(dictionary: val)
                        arrayValue.append(l)
                    }
                    super.setValue(arrayValue, forKey: key)
                    
                }
                else {
                    println("\n#### FATAL ERROR ####\n key : \(key) is not initialised like this [CUSTOM_TYPE()]")
                    fatalError("Error in parsing see console for more information")
                    
                }
                
            }
            else if (value is Dictionary<String, AnyObject> && !(self.valueForKey(key) is Dictionary<String, AnyObject>)) {
                var arrayValue = self.valueForKey(key) as ABModel
                var t = arrayValue.dynamicType
                var val = value as Dictionary<String, AnyObject>
                
                arrayValue = t(dictionary: val)
                super.setValue(arrayValue, forKey: key)
            }
            else {
                super.setValue(value, forKey: key)
            }
        }
        
    }
    
    /**
    * You should override this method only if you want to rename JSON key
    */
    public func replaceKey(key:String) -> String {
        
        return "";
    }
}
