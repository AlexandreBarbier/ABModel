//
//  CloudKitExtension.swift
//  ABModel
//
//  Created by Alexandre barbier on 07/12/15.
//  Copyright © 2015 abarbier. All rights reserved.
//

import UIKit
import CloudKit

public class ABModelCloudKit : ABModel {
    public class func recordType() -> String {
        return ""
    }
    public var record : CKRecord!
    public var recordId : CKRecordID!
    
    public required init(record:CKRecord, recordId:CKRecordID) {
        let keys = record.allKeys()
        let dictionary = record.dictionaryWithValuesForKeys(keys)
        super.init(dictionary: dictionary)
        self.recordId = recordId
        self.record = record
    }
    
    public required override init() {
        let newRecord = CKRecord(recordType: self.dynamicType.recordType())
        super.init(dictionary: newRecord.dictionaryWithValuesForKeys(newRecord.allKeys()))
        self.record = newRecord
        self.recordId = newRecord.recordID
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.recordId = aDecoder.decodeObjectForKey("recordId") as! CKRecordID
        self.record = aDecoder.decodeObjectForKey("record") as! CKRecord
    }
    
    public override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.recordId, forKey: "recordId")
        aCoder.encodeObject(self.record, forKey: "record")
    }
    
    public required init(dictionary: Dictionary<String, AnyObject>) {
        super.init(dictionary: dictionary)
    }
    
    public func updateRecord(completion:((record:CKRecord?, error:NSError?) -> Void)? = nil) {
        let operation = CKModifyRecordsOperation(recordsToSave: [self.toRecord()], recordIDsToDelete: nil)
        operation.savePolicy = .ChangedKeys
        operation.perRecordCompletionBlock = { (record, error) in
            guard let rec = record else {
                if let cp = completion {
                    print("public save \(error)")
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        cp(record: record, error: error)
                    })
                }
                return
            }
            self.record = rec
            self.recordId = rec.recordID
            if let cp = completion {
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    cp(record: rec, error: error)
                })
            }
        }
        CloudKitManager.publicDB.addOperation(operation)
    }
    
    public class func create<T:ABModelCloudKit>(completion:(record:CKRecord?, error:NSError?) -> Void) -> T {
        let obj = T()
        let operation = CKModifyRecordsOperation(recordsToSave: [obj.toRecord()], recordIDsToDelete: nil)
        operation.perRecordCompletionBlock = { (record, error) in
            guard let record = record else {
                print("CKManager create \(error)")
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    completion(record: nil, error: error)
                })
                return
            }
            obj.record = record
            obj.recordId = record.recordID
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                completion(record: record, error: error)
            })
        }
        CloudKitManager.publicDB.addOperation(operation)
        return obj
    }
    
    public func publicSave(completion:((record:CKRecord?, error:NSError?) -> Void)? = nil) {
        let saveOp = CKModifyRecordsOperation(recordsToSave: [self.toRecord()], recordIDsToDelete: nil)
        saveOp.savePolicy = .AllKeys
        saveOp.perRecordCompletionBlock =  { (record, error) -> Void in
            guard let rec = record else {
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    completion?(record: record, error: error)
                })
                if let retryAfterValue = error?.userInfo[CKErrorRetryAfterKey] as? NSTimeInterval  {
                    debugPrint("should retry")
                    self.performSelector(#selector(ABModelCloudKit.publicSave(_:)), withObject: nil, afterDelay:retryAfterValue)
                }
                return
            }
            self.record = rec
            self.recordId = rec.recordID
            
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                completion?(record: rec, error: error)
            })
            
        }
        CloudKitManager.publicDB.addOperation(saveOp)
        
    }
    
    public func saveBulk(records:[CKRecord],completion:(() -> Void)?) {
        var rec = [self.toRecord()]
        rec.appendContentsOf(records)
        let saveOp = CKModifyRecordsOperation(recordsToSave: rec, recordIDsToDelete: nil)
        
        if let cmp = completion {
            saveOp.completionBlock = {
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    cmp()
                })
            }
        }
        CloudKitManager.publicDB.addOperation(saveOp)
    }
    
    public class func saveBulk(records:[CKRecord],completion:(() -> Void)?) {
        let saveOp = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        
        if let cmp = completion {
            saveOp.completionBlock = {
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    cmp()
                })
            }
        }
        CloudKitManager.publicDB.addOperation(saveOp)
    }
    
    public func refresh<T:ABModelCloudKit>(completion:((updatedObj:T?)->Void)? = nil) {
        CloudKitManager.publicDB.fetchRecordWithID(self.recordId) { (record, error) -> Void in
            guard let record = record else {
                print(error)
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    completion?(updatedObj: nil)
                })
                return
            }
            let update = T(record: record, recordId: record.recordID)
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                completion?(updatedObj: update)
            })
        }
    }
    
    public func privateSave(completion:(record:CKRecord?, error:NSError?)-> Void) {
        CloudKitManager.privateDB.saveRecord(self.toRecord()) { (record, error) -> Void in
            completion(record: record, error: error)
        }
    }
    
    public func toRecord() -> CKRecord {
        
        let dictionary = self.toJSON()
        
        for (key, value) in dictionary {
            
            let val = value as? CKRecordValue
            
            if val is [CKRecordValue] {
                let arrayVal = val as? [CKRecordValue]
                if arrayVal!.count > 0 {
                    self.record.setObject(val, forKey: key)
                }
            }
            else {
                self.record!.setObject(val, forKey: key)
            }
        }
        return record!
    }
    
    public class func getRecord(predicateFormat:String, completion:(record:CKRecord?, error:NSError?) -> Void) {
        let query = CKQuery(recordType: self.recordType(), predicate: NSPredicate(format: predicateFormat, argumentArray: nil))
        CloudKitManager.publicDB.performQuery(query, inZoneWithID: nil) { (records, error) -> Void in
            guard let records = records, first = records.first else {
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    completion(record:nil,error:error)
                })
                return
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                completion(record:first,error:error)
            })
        }
    }
    
    public func remove() {
        let deleteOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [self.recordId])
        deleteOp.perRecordCompletionBlock = {(record,error) in
            print(error)
        }
        CloudKitManager.publicDB.addOperation(deleteOp)
    }
    
    public class func removeRecordId(record:CKRecordID) {
        let deleteOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record])
        deleteOp.perRecordCompletionBlock = {(record,error) in
            print(error)
        }
        CloudKitManager.publicDB.addOperation(deleteOp)
    }
    
    public func getReferences<T:ABModelCloudKit>(references:[CKReference],completion:((results:[T], error:NSError?) -> Void)? = nil, perRecordCompletion:((result:T?, error:NSError?) -> Void)? = nil) {
        var results = [T]()
        let refs = references.map({ (reference) -> CKRecordID in
            reference.recordID
        })
        let op = CKFetchRecordsOperation(recordIDs: refs)
        op.queuePriority = .VeryHigh
        if let completion = completion {
            op.fetchRecordsCompletionBlock = { (recordDictionary, error) in
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    for (key, value) in recordDictionary! {
                        results.append(T(record:value, recordId:key))
                    }
                    completion(results:results, error:nil)
                })
            }
        }
        if let perRecordCompletion = perRecordCompletion {
            op.perRecordCompletionBlock = { (record,recordId, error) in
                guard let recordId = recordId, record = record else {
                    NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                        perRecordCompletion(result: nil, error: error)
                    })
                    return
                }
                let project = T(record:record, recordId:recordId)
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    perRecordCompletion(result: project, error: error)
                })
            }
        }
        CloudKitManager.publicDB.addOperation(op)
    }
}

public class CloudKitManager {
    public static var container = CKContainer.defaultContainer()
    public static var publicDB = CloudKitManager.container.publicCloudDatabase
    public static var privateDB = CloudKitManager.container.privateCloudDatabase
    public static var isAvailable : Bool = false
    public static var cloudkitQueue = NSOperationQueue()
    
    public class func userAlreadyConnectThisDevice() -> Bool {
        return NSUserDefaults().boolForKey("userConnect")
        //NSUserDefaults().setBool(true, forKey: "userConnect")
    }
    
    public class func availability(completion:(available:Bool, alert: UIAlertController?) -> Void) {
        CloudKitManager.container.accountStatusWithCompletionHandler { (status, error) -> Void in
            switch status {
            case .Available:
                CloudKitManager.isAvailable = true
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    completion(available: true, alert: nil)
                })
                break
            case .CouldNotDetermine :
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    let alert = UIAlertController(title: "An error occured while connecting to your iCloud account", message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                    completion(available: false, alert: alert)
                })
                break
            case .NoAccount:
                CloudKitManager.isAvailable = false
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    let alert = UIAlertController(title: "iCloud account required", message: "To use this app you need to be connected to your iCloud account", preferredStyle: UIAlertControllerStyle.Alert)
                    completion(available: false, alert: alert)
                })
                break
            case .Restricted :
                CloudKitManager.isAvailable = false
                NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                    let alert = UIAlertController(title: "iCloud capabilities required", message: "To use this app you need to be connected to your iCloud account and set iCloud Drive enable", preferredStyle: UIAlertControllerStyle.Alert)
                    completion(available: false, alert: alert)
                })
                break
            }
        }
    }
}
