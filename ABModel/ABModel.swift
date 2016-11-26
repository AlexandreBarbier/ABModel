//
//  ABModel.swift
//  ABModel
//
//  Created by Alexandre Barbier on 23/08/14.
//  Copyright (c) 2014 abarbier. All rights reserved.
//

/**
 *
 * You just need to inherit from this class to be able to create object from JSON
 * You have to name your properties like the JSON keys or override the method replaceKey to rename a JSON key
 * If you have an array<T> where T does not inherit from ABModel or is not a basic type you should use the ignore key method and fill the array
 * yourself to avoid a memory leak caused by the casting from NSArray to Array
 *
 */
fileprivate struct ABCached {
    static var shared = ABCached()
    var appType = [String: AnyClass?]()
    var mirrorKeys = [String:[String]]()
}


open class ABModel: NSObject, NSCoding {
    
    open static var debug: Bool = false
    open static let reg  = try! NSRegularExpression(pattern: "[0-9]+([a-zA-Z]+)", options: NSRegularExpression.Options.caseInsensitive)
    static let rootKey = "root"
    static let superKey = "super"
    
    open override var description: String {
        get
        {
            return "ABModel super class you should override this method in \(NSStringFromClass(type(of: self)))"
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        do {
            let dico : Dictionary<String, AnyObject>?
            if #available(iOS 9.0, *) {
                dico = try aDecoder.decodeTopLevelObject(forKey: ABModel.rootKey) as? Dictionary<String, AnyObject>
            }
            else {
                dico = aDecoder.decodeObject(forKey: ABModel.rootKey) as? Dictionary<String, AnyObject>
            }
            
            guard let dictionary = dico else {
                return
            }
            parse(dictionary: dictionary)
            
        } catch {
            ABModel.dPrint(value: "init with coder error")
            return
        }
    }
    
    open func encode(with aCoder: NSCoder) {
        let dico = toJSON()
        aCoder.encode(dico, forKey: ABModel.rootKey)
    }
    
    public override init() {
        super.init()
    }
    
    public required init(dictionary:Dictionary<String, AnyObject>) {
        super.init()
        
        parse(dictionary: dictionary)
    }
    
}

// MARK: - override this if needed
extension ABModel {
    /**
     * You should override this method only if you want to ignore JSON key
     */
    open func ignoreKey(_ key: String, value: AnyObject) -> Bool {
        return false
    }
    
    /**
     * You should override this method only if you want to rename JSON key
     */
    open func replaceKey(_ key: String) -> String {
        return ""
    }
}

// MARK: - Helper
extension ABModel {
    
    class func dPrint (value: Any?) -> Void {
        ABModel.debug ? print("----- ABModel\tDEBUG ------\n\(value ?? "value is nil")\n\t-----") : ()
    }
    
    class func errorPrint(value: Any?) -> Void {
        print("----- ABModel\tERROR ------\n\(value ?? "value is nil")\n\t-----")
    }
    
    open func toJSON() -> Dictionary<String, AnyObject> {
        var json: Dictionary<String, AnyObject> = [:]
        let keys:[String] = fillMirrorKeys()
        
        for key in keys {
            if responds(to: Selector(key)), let val = self.value(forKey: key) as? NSObject {
                json.updateValue(val, forKey: key)
                
            }
        }
        return json
    }
}

// MARK: - parsing
extension ABModel {
    func parse(dictionary:Dictionary<String, AnyObject>) {
        
        var finalDictionnary = dictionary
        
        for (key, val) in dictionary {
            if !responds(to: Selector(key)) {
                let replacementKey = replaceKey(key)
                finalDictionnary.remove(at: finalDictionnary.index(forKey: key)!)
                if !replacementKey.isEmpty {
                    finalDictionnary.updateValue(val, forKey: replacementKey)
                }
                else {
                    ABModel.dPrint(value:"Forgoten key : \(key) in \(type(of: self))")
                }
            }
            if ignoreKey(key, value: val) {
                finalDictionnary.remove(at: finalDictionnary.index(forKey: key)!)
            }
        }
        setValuesForKeys(finalDictionnary)
        cleanModel(dictionnary: finalDictionnary)
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
            ABModel.dPrint(value:"Value for key : \(key) in \(type(of: self)) is nil")
            if responds(to: Selector(key)), let objectValue = self.value(forKey: key), var newArray = objectValue as? [ABModel] {
                newArray.removeAll()
            }
            return
        }
        var newValue : Any! = value
        let objectValue = self.value(forKey: key)
        if let arrayVal = value as? [AnyObject], arrayVal.count > 0 && (value is [AnyObject] && value is Array<Dictionary<String, AnyObject>>) {
            guard var newArray = objectValue as? [ABModel] , newArray.count > 0 else {
                ABModel.errorPrint(value:"\n#### FATAL ERROR ####\n key : \(key) is not initialised like this [CUSTOM_TYPE()] in \(NSStringFromClass(type(of: self)))")
                fatalError("Error in parsing see console for more information")
            }
            let elementType = type(of: newArray[0])
            newArray.removeAll(keepingCapacity: false)
            for val in value as! Array<Dictionary<String, AnyObject>> {
                let l = elementType.init(dictionary: val)
                newArray.append(l)
            }
            newValue = newArray
        }
        else if (value is Dictionary<String, AnyObject> && !(objectValue is Dictionary<String, AnyObject>)) {
            if  let objectType = getAttributeType(for:key) as? ABModel.Type,
                let objectValue = value as? Dictionary<String, AnyObject> {
                newValue = objectType.init(dictionary: objectValue)
            }
        }
        super.setValue(newValue, forKey: key)
    }
}

// MARK: - private
extension ABModel {
    
    func applyRegex(str:NSString) -> String {
        let matches = ABModel.reg.matches(in: str as String, options: NSRegularExpression.MatchingOptions.reportCompletion, range: NSRange(location: 0, length: str.length))
        let result = matches.map({ (matchResult) -> String in
            return str.substring(with: matchResult.rangeAt(1))
        }).joined(separator: ".")
        return result
    }
    
    func getAttributeType(for key: String) -> AnyClass? {
        if let cachedClass = ABCached.shared.appType["\(type(of: self)).\(key)"] {
            return cachedClass
        }
        var objectClass: AnyClass? = nil
        if let UTFKey = (key as NSString).utf8String {
            let propAttr = property_getAttributes(class_getProperty(type(of: self), UTFKey))
            let str = NSString.init(utf8String: propAttr!)!
            let result = applyRegex(str: str)
            objectClass = NSClassFromString(result)
            ABCached.shared.appType.updateValue(objectClass, forKey: "\(type(of: self)).\(key)")
        }
        
        return objectClass
    }
    
    func fillMirrorKeys() -> [String] {
        let keys:[String]
        if let k = ABCached.shared.mirrorKeys["\(type(of: self))"] {
            keys = k
        }
        else {
            var mkeys : Mirror? = Mirror(reflecting: self)
            var k : [String] = []
            while mkeys != nil {
                let children = mkeys!.children
                for value in children.enumerated() {
                    if let key = value.element.0, key != ABModel.superKey, key != "", responds(to: Selector(key)) {
                        k.append(key)
                    }
                }
                mkeys = mkeys!.superclassMirror
            }
            ABCached.shared.mirrorKeys.updateValue(k, forKey: "\(type(of: self))")
            keys = k
        }
        return keys
    }
    
    func cleanModel(dictionnary:Dictionary<String, AnyObject>) {
        let keys:[String] = fillMirrorKeys()
        for key in keys {
            if dictionnary.contains(where: { (k: String, value: AnyObject) -> Bool in
                return key == k
            }) {
                continue
            }
            if responds(to: Selector(key)) {
                let objectValue = self.value(forKey: key)
                if objectValue is [ABModel] {
                    super.setValue([], forKey: key)
                }
            }
        }
    }
}
