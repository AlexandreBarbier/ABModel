//
//  CloudKitExtension.swift
//  ABModel
//
//  Created by Alexandre barbier on 07/12/15.
//  Copyright © 2015 abarbier. All rights reserved.
//

import UIKit
import CloudKit

open class ABModelCloudKit : ABModel {
    open class func recordType() -> String {
        return ""
    }
    open var record : CKRecord!
    open var recordId : CKRecordID!
    
    public required init(record:CKRecord, recordId:CKRecordID) {
        let keys = record.allKeys()
        let dictionary = record.dictionaryWithValues(forKeys: keys)
        super.init(dictionary: dictionary as Dictionary<String, AnyObject>)
        self.recordId = recordId
        self.record = record
    }
    
    public required override init() {
        let newRecord = CKRecord(recordType: type(of: self).recordType())
        super.init(dictionary: newRecord.dictionaryWithValues(forKeys: newRecord.allKeys()) as Dictionary<String, AnyObject>)
        self.record = newRecord
        self.recordId = newRecord.recordID
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.recordId = aDecoder.decodeObject(forKey: "recordId") as! CKRecordID
        self.record = aDecoder.decodeObject(forKey: "record") as! CKRecord
    }
    
    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(self.recordId, forKey: "recordId")
        aCoder.encode(self.record, forKey: "record")
    }
    
    public required init(dictionary: Dictionary<String, AnyObject>) {
        super.init(dictionary: dictionary)
    }
    
    open func updateRecord(_ completion:((_ record:CKRecord?, _ error:NSError?) -> Void)? = nil) {
        let operation = CKModifyRecordsOperation(recordsToSave: [self.toRecord()], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.perRecordCompletionBlock = { (record, error) in
            guard let rec = record else {
                print("public save \(error)")
                OperationQueue.main.addOperation({ () -> Void in
                    completion?(record, error as NSError?)
                })
                return
            }
            self.record = rec
            self.recordId = rec.recordID
            OperationQueue.main.addOperation({ () -> Void in
                completion?(rec, error as NSError?)
            })
        }
        CloudKitManager.publicDB.add(operation)
    }
    
    open class func create<T:ABModelCloudKit>(_ completion:@escaping (_ record:CKRecord?, _ error:NSError?) -> Void) -> T {
        let obj = T()
        let operation = CKModifyRecordsOperation(recordsToSave: [obj.toRecord()], recordIDsToDelete: nil)
        operation.perRecordCompletionBlock = { (record, error) in
            guard let record = record else {
                print("CKManager create \(error)")
                OperationQueue.main.addOperation({ () -> Void in
                    completion(nil, error as NSError?)
                })
                return
            }
            obj.record = record
            obj.recordId = record.recordID
            OperationQueue.main.addOperation({ () -> Void in
                completion(record, error as NSError?)
            })
        }
        CloudKitManager.publicDB.add(operation)
        return obj
    }
    
    open func publicSave(_ completion:((_ record:CKRecord?, _ error:NSError?) -> Void)? = nil) {
        let saveOp = CKModifyRecordsOperation(recordsToSave: [self.toRecord()], recordIDsToDelete: nil)
        saveOp.savePolicy = .allKeys
        saveOp.perRecordCompletionBlock =  { (record, error) -> Void in
            guard let rec = record else {
                OperationQueue.main.addOperation({ () -> Void in
                    completion?(nil, error as NSError?)
                })
                if let retryAfterValue = (error as? NSError)?.userInfo[CKErrorRetryAfterKey] as? TimeInterval  {
                    debugPrint("should retry")
                    self.perform(#selector(ABModelCloudKit.publicSave(_:)), with: nil, afterDelay:retryAfterValue)
                }
                return
            }
            self.record = rec
            self.recordId = rec.recordID
            
            OperationQueue.main.addOperation({ () -> Void in
                completion?(rec, error as NSError?)
            })
            
        }
        CloudKitManager.publicDB.add(saveOp)
        
    }
    
    open func saveBulk(_ records:[CKRecord],completion:(() -> Void)?) {
        var rec = [self.toRecord()]
        rec.append(contentsOf: records)
        let saveOp = CKModifyRecordsOperation(recordsToSave: rec, recordIDsToDelete: nil)
        
        saveOp.completionBlock = {
            OperationQueue.main.addOperation({ () -> Void in
                completion?()
            })
        }
        CloudKitManager.publicDB.add(saveOp)
    }
    
    open class func saveBulk(_ records:[CKRecord],completion:(() -> Void)?) {
        let saveOp = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        
        saveOp.completionBlock = {
            OperationQueue.main.addOperation({ () -> Void in
                completion?()
            })
        }
        CloudKitManager.publicDB.add(saveOp)
    }
    
    open func refresh<T:ABModelCloudKit>(_ completion:((_ updatedObj:T?)->Void)? = nil) {
        CloudKitManager.publicDB.fetch(withRecordID: self.recordId) { (record, error) -> Void in
            guard let record = record else {
                print(error)
                OperationQueue.main.addOperation({ () -> Void in
                    completion?(nil)
                })
                return
            }
            let update = T(record: record, recordId: record.recordID)
            OperationQueue.main.addOperation({ () -> Void in
                completion?(update)
            })
        }
    }
    
    open func privateSave(_ completion:@escaping (_ record:CKRecord?, _ error:Error?)-> Void) {
		
        CloudKitManager.privateDB.save(self.toRecord(), completionHandler: { (record, error) -> Void in
            completion(record, error)
        }) 
    }
    
    open func toRecord() -> CKRecord {
        
        let dictionary = self.toJSON()
        
        for (key, value) in dictionary {
            
            let val = value as? CKRecordValue
            
            if val is [CKRecordValue] {
                if let arrayVal = val as? [CKRecordValue], arrayVal.count > 0 {
                    self.record.setObject(val, forKey: key)
                }
            }
            else {
                self.record.setObject(val, forKey: key)
            }
        }
        return record
    }
    
    open class func getRecord(_ predicateFormat:String, completion:@escaping (_ record:CKRecord?, _ error:NSError?) -> Void) {
        let query = CKQuery(recordType: self.recordType(), predicate: NSPredicate(format: predicateFormat, argumentArray: nil))
        CloudKitManager.publicDB.perform(query, inZoneWith: nil) { (records, error) -> Void in
            guard let records = records, let first = records.first else {
                OperationQueue.main.addOperation({ () -> Void in
                    completion(nil, error as NSError?)
                })
                return
            }
            OperationQueue.main.addOperation({ () -> Void in
                completion(first, error as NSError?)
            })
        }
    }
    
    open func remove() {
        let deleteOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [self.recordId])
        deleteOp.perRecordCompletionBlock = {(record, error) in
            print(error)
        }
        CloudKitManager.publicDB.add(deleteOp)
    }
    
    open class func removeRecordId(_ record:CKRecordID) {
        let deleteOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record])
        deleteOp.perRecordCompletionBlock = {(record,error) in
            print(error)
        }
        CloudKitManager.publicDB.add(deleteOp)
    }
    
    open func getReferences<T:ABModelCloudKit>(_ references:[CKReference], completion:((_ results:[T], _ error:NSError?) -> Void)? = nil, perRecordCompletion:((_ result:T?, _ error:NSError?) -> Void)? = nil) {
        var results = [T]()
        let refs = references.map({ (reference) -> CKRecordID in
            reference.recordID
        })
        let op = CKFetchRecordsOperation(recordIDs: refs)
        op.queuePriority = .veryHigh
        if let completion = completion {
            op.fetchRecordsCompletionBlock = { (recordDictionary, error) in
                guard let recordDictionary = recordDictionary else {
                    completion([], nil)
                    return
                }
                guard error == nil else {
                    completion([], error as? NSError)
                    return
                }
                OperationQueue.main.addOperation({ () -> Void in
                    for (key, value) in recordDictionary {
                        results.append(T(record:value, recordId:key))
                    }
                    completion(results, nil)
                })
            }
        }
        if let perRecordCompletion = perRecordCompletion {
            op.perRecordCompletionBlock = { (record, recordId, error) in
                guard error == nil else {
                    perRecordCompletion(nil, error as? NSError)
                    return
                }
                guard let recordId = recordId, let record = record else {
                    
                    OperationQueue.main.addOperation({ () -> Void in
                        perRecordCompletion(nil, error as NSError?)
                    })
                    return
                }
                let project = T(record:record, recordId:recordId)
                OperationQueue.main.addOperation({ () -> Void in
                    perRecordCompletion(project, error as NSError?)
                })
            }
        }
        CloudKitManager.publicDB.add(op)
    }
}

open class CloudKitManager {
    open static var container = CKContainer.default()
    open static var publicDB = CloudKitManager.container.publicCloudDatabase
    open static var privateDB = CloudKitManager.container.privateCloudDatabase
    open static var isAvailable : Bool = false
    open static var cloudkitQueue = OperationQueue()
    
    open class func userAlreadyConnectThisDevice() -> Bool {
        return UserDefaults().bool(forKey: "userConnect")
    }
    
    open class func availability(_ completion:@escaping (_ available:Bool, _ alert: UIAlertController?) -> Void) {
        CloudKitManager.container.accountStatus { (status, error) -> Void in
            switch status {
            case .available:
                CloudKitManager.isAvailable = true
                OperationQueue.main.addOperation({ () -> Void in
                    completion(true, nil)
                })
                break
            case .couldNotDetermine :
                OperationQueue.main.addOperation({ () -> Void in
                    let alert = UIAlertController(title: "An error occured while connecting to your iCloud account", message: error!.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
                    completion(false, alert)
                })
                break
            case .noAccount:
                CloudKitManager.isAvailable = false
                OperationQueue.main.addOperation({ () -> Void in
                    let alert = UIAlertController(title: "iCloud account required", message: "To use this app you need to be connected to your iCloud account", preferredStyle: UIAlertControllerStyle.alert)
                    completion(false, alert)
                })
                break
            case .restricted :
                CloudKitManager.isAvailable = false
                OperationQueue.main.addOperation({ () -> Void in
                    let alert = UIAlertController(title: "iCloud capabilities required", message: "To use this app you need to be connected to your iCloud account and set iCloud Drive enable", preferredStyle: UIAlertControllerStyle.alert)
                    completion(false, alert)
                })
                break
            }
        }
    }
}
