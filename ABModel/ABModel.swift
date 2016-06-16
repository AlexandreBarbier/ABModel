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
 * If you have an array<T> where T does not inherit from ABModel or is not a basic type you should use the ingnore key method and fill the array
 * yourself to avoid a memory leak caused by the casting from NSArray to Array
 *
 */

public class ABModel: NSObject, NSCoding {
    
    public override var description :String {
        get
        {
            return "ABModel super class you should override this method in \(NSStringFromClass(self.dynamicType))"
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        let dictionary = aDecoder.decodeObjectForKey("root") as! Dictionary<String, AnyObject>
        var finalDictionnary =  aDecoder.decodeObjectForKey("root") as! Dictionary<String, AnyObject>
        
        for (key, value) in dictionary {
            if !self.respondsToSelector(Selector(key)) {
                let replacementKey = self.replaceKey(key)
                if replacementKey.isEmpty {
                    finalDictionnary.removeAtIndex(finalDictionnary.indexForKey(key)!)
                    debugPrint("Forgoten key : \(key) in \(NSStringFromClass(self.dynamicType))")
                }
                else {
                    finalDictionnary[replacementKey] = value;
                    finalDictionnary.removeAtIndex(finalDictionnary.indexForKey(key)!)
                }
            }
            if self.ignoreKey(key, value: value) {
                finalDictionnary.removeAtIndex(finalDictionnary.indexForKey(key)!)
            }
            
        }
        self.setValuesForKeysWithDictionary(finalDictionnary)
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        let dico = self.toJSON()
        aCoder.encodeObject(dico, forKey: "root")
    }
    
    public override init() {
        super.init()
    }
    
    public required init(dictionary:Dictionary<String, AnyObject>) {
        super.init()
        var finalDictionnary = dictionary
        
        for (key, value) in dictionary {

            if !self.respondsToSelector(Selector(key)) {
               
                    let replacementKey = self.replaceKey(key)
                    if replacementKey.isEmpty {
                        finalDictionnary.removeAtIndex(finalDictionnary.indexForKey(key)!)
                        debugPrint("Forgoten key : \(key) in \(NSStringFromClass(self.dynamicType))")
                    }
                    else {
                        finalDictionnary[replacementKey] = value
                        finalDictionnary.removeAtIndex(finalDictionnary.indexForKey(key)!)
                    }
              

            }
            if self.ignoreKey(key, value: value) {
                finalDictionnary.removeAtIndex(finalDictionnary.indexForKey(key)!)
            }
        }
        self.setValuesForKeysWithDictionary(finalDictionnary)
    }
    
    override public func setValue(value: AnyObject!, forKey key: String)  {
        
        /**
        * here we want to check the type of the property named key to know if it's an array / dictionnary.
        * if it's an array / dictionnary we have to know the objects type contain in it to make something smart
        * if we can't find a solution here we just have to override setValue in each subclass and apply the correct treatment
        * for nested properties
        */
        //here we check if the value is nil to avoid crash
        guard value != nil else {
            return
        }
        if (value is [AnyObject] && value is Array<Dictionary<String, AnyObject>>) {
            var k = self.valueForKey(key) as? [ABModel]
            
            guard let val = k where val.count > 0 else {
                print("\n#### FATAL ERROR ####\n key : \(key) is not initialised like this [CUSTOM_TYPE()] in \(NSStringFromClass(self.dynamicType))")
                fatalError("Error in parsing see console for more information")
            }
            let t = val[0].dynamicType
            k!.removeAll(keepCapacity: false)
            for val in value as! Array<Dictionary<String, AnyObject>> {
                let l = t.init(dictionary: val)
                k!.append(l)
            }
            super.setValue(k, forKey: key)
            
        }
        else if (value is Dictionary<String, AnyObject> &&
            !(self.valueForKey(key) is Dictionary<String, AnyObject>)) {
                if let k = self.valueForKey(key) as? ABModel, val = value as? Dictionary<String, AnyObject> {
                    let t = k.dynamicType
                    let newVal = t.init(dictionary: val)
                    super.setValue(newVal, forKey: key)
                }
        }
        else {
            super.setValue(value, forKey: key)
        }
    }
    
    /**
     * You should override this method only if you want to ignore JSON key
     */
    public func ignoreKey(key:String, value:AnyObject) -> Bool {
        return false
    }
    
    /**
     * You should override this method only if you want to rename JSON key
     */
    public func replaceKey(key:String) -> String {
        return ""
    }
    
    public func toJSON() -> Dictionary<String, AnyObject> {
        let k = Mirror(reflecting: self)
        let children = AnyRandomAccessCollection(k.children)
        var json:Dictionary<String, AnyObject> = [:]
        for (_, value) in  (children?.enumerate())! {
            if value.0 != "super" {
                if let val = value.1 as? NSObject {
                    if val != "" {
                        json.updateValue(val, forKey: value.0!)
                    }
                }
            }
        }
        return json
    }
}