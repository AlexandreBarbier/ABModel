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



open class ABModel: NSObject, NSCoding {
    open static var debug:Bool = false
    
    class func dPrint (value: Any?) -> Void {
        ABModel.debug ? debugPrint(value) : ()
    }
    
    open override var description :String {
        get
        {
            return "ABModel super class you should override this method in \(NSStringFromClass(type(of: self)))"
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        let dictionary = aDecoder.decodeObject(forKey: "root") as! Dictionary<String, AnyObject>
        var finalDictionnary =  aDecoder.decodeObject(forKey: "root") as! Dictionary<String, AnyObject>
        
        for (key, value) in dictionary {
            if !self.responds(to: Selector(key)) {
                let replacementKey = self.replaceKey(key)
                if replacementKey.isEmpty {
                    finalDictionnary.remove(at: finalDictionnary.index(forKey: key)!)
                    debugPrint("Forgoten key : \(key) in \(NSStringFromClass(type(of: self)))")
                }
                else {
                    finalDictionnary[replacementKey] = value;
                    finalDictionnary.remove(at: finalDictionnary.index(forKey: key)!)
                }
            }
            if self.ignoreKey(key, value: value) {
                finalDictionnary.remove(at: finalDictionnary.index(forKey: key)!)
            }
            
        }
        self.setValuesForKeys(finalDictionnary)
    }
    
    open func encode(with aCoder: NSCoder) {
        let dico = self.toJSON()
        aCoder.encode(dico, forKey: "root")
    }
    
    public override init() {
        super.init()
    }
    
    public required init(dictionary:Dictionary<String, AnyObject>) {
        super.init()
        var finalDictionnary = dictionary
        
        for (key, value) in dictionary {

            if !self.responds(to: Selector(key)) {
                let replacementKey = self.replaceKey(key)
                if replacementKey.isEmpty {
                    finalDictionnary.remove(at: finalDictionnary.index(forKey: key)!)
                    debugPrint("Forgoten key : \(key) in \(NSStringFromClass(type(of: self)))")
                }
                else {
                    finalDictionnary[replacementKey] = value
                    finalDictionnary.remove(at: finalDictionnary.index(forKey: key)!)
                }
            }
            if self.ignoreKey(key, value: value) {
                finalDictionnary.remove(at: finalDictionnary.index(forKey: key)!)
            }
        }
        self.setValuesForKeys(finalDictionnary)
    }
    
    override open func setValue(_ value: Any!, forKey key: String)  {
        
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
            var k = self.value(forKey: key) as? [ABModel]
            
            guard let val = k , val.count > 0 else {
                print("\n#### FATAL ERROR ####\n key : \(key) is not initialised like this [CUSTOM_TYPE()] in \(NSStringFromClass(type(of: self)))")
                fatalError("Error in parsing see console for more information")
            }
            let t = type(of: val[0])
            k!.removeAll(keepingCapacity: false)
            for val in value as! Array<Dictionary<String, AnyObject>> {
                let l = t.init(dictionary: val)
                k!.append(l)
            }
            super.setValue(k, forKey: key)
            
        }
        else if (value is Dictionary<String, AnyObject> &&
            !(self.value(forKey: key) is Dictionary<String, AnyObject>)) {
                if let k = self.value(forKey: key) as? ABModel, let val = value as? Dictionary<String, AnyObject> {
                    let t = type(of: k)
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
    open func ignoreKey(_ key:String, value:AnyObject) -> Bool {
        return false
    }
    
    /**
     * You should override this method only if you want to rename JSON key
     */
    open func replaceKey(_ key:String) -> String {
        return ""
    }
    
    open func toJSON() -> Dictionary<String, AnyObject> {
        let k = Mirror(reflecting: self)
        let children = AnyRandomAccessCollection(k.children)
        var json:Dictionary<String, AnyObject> = [:]
        for (_, value) in  (children?.enumerated())! {
            if let key = value.0, value.0 != "super" {
                if let val = value.1 as? NSObject {
					if key != "" {
                        json.updateValue(val, forKey: key)
                    }
                }
            }
        }
        return json
    }
}
