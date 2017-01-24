//
//  CloudKitExtension.swift
//  ABModel
//
//  Created by Alexandre barbier on 07/12/15.
//  Copyright © 2015 abarbier. All rights reserved.
//
import UIKit
import CloudKit

open class ABModelCloudKit: ABModel {
    open class func recordType() -> String {
        return ""
    }
    open var record: CKRecord!
    open var recordId: CKRecordID!

    public required init(record rec: CKRecord, recordId rId: CKRecordID) {
        let keys = record.allKeys()
        let dictionary = record.dictionaryWithValues(forKeys: keys)
        super.init(dictionary: dictionary as [String: AnyObject])
        recordId = rId
        record = rec
    }

    public required override init() {
        let newRecord = CKRecord(recordType: type(of: self).recordType())
        super.init(dictionary: newRecord.dictionaryWithValues(forKeys: newRecord.allKeys()) as [String: AnyObject])
        record = newRecord
        recordId = newRecord.recordID
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if let recId = aDecoder.decodeObject(forKey: "recordId") as? CKRecordID {
            recordId = recId
        }
        if let rec = aDecoder.decodeObject(forKey: "record") as? CKRecord {
            record = rec
        }

    }

    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(recordId, forKey: "recordId")
        aCoder.encode(record, forKey: "record")
    }

    public required init(dictionary: [String: AnyObject]) {
        super.init(dictionary: dictionary)
    }
}

extension ABModelCloudKit {
    open func updateRecord(_ completion:((_ record: CKRecord?, _ error: NSError?) -> Void)? = nil) {
        let operation = CKModifyRecordsOperation(recordsToSave: [toRecord()], recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.perRecordCompletionBlock = { (record, error) in
            guard error == nil else {
                ABModel.errorPrint(value:"public save error\(error)")
                OperationQueue.main.addOperation({ () -> Void in
                    completion?(record, error as NSError?)
                })
                return
            }
            self.record = record
            self.recordId = record.recordID
            OperationQueue.main.addOperation({ () -> Void in
                completion?(record, error as NSError?)
            })
        }
        CloudKitManager.publicDB.add(operation)
    }

    open class func create<T: ABModelCloudKit>(_ completion: ((_ record: CKRecord?,
        _ error: NSError?) -> Void)? = nil) -> T {
        let obj = T()
        let operation = CKModifyRecordsOperation(recordsToSave: [obj.toRecord()], recordIDsToDelete: nil)

        operation.perRecordCompletionBlock = { (record, error) in
            guard error == nil else {
                ABModel.errorPrint(value:"CKManager create \(error)")
                OperationQueue.main.addOperation({ () -> Void in
                    completion?(nil, error as NSError?)
                })
                return
            }
            obj.record = record
            obj.recordId = record.recordID
            OperationQueue.main.addOperation({ () -> Void in
                completion?(record, error as NSError?)
            })
        }
        CloudKitManager.publicDB.add(operation)
        return obj
    }

    open func publicSave(_ completion:((_ record: CKRecord?, _ error: NSError?) -> Void)? = nil) {
        let saveOp = CKModifyRecordsOperation(recordsToSave: [self.toRecord()], recordIDsToDelete: nil)
        saveOp.savePolicy = .allKeys
        saveOp.perRecordCompletionBlock = { (record, error) -> Void in
            guard error == nil else {
                OperationQueue.main.addOperation({ () -> Void in
                    error != nil ? ABModel.errorPrint(value: "public save error\(error)") : ()
                    completion?(nil, error as NSError?)
                })
                if let retryAfterValue = (error as? NSError)?.userInfo[CKErrorRetryAfterKey] as? TimeInterval {
                    ABModel.dPrint(value: "should retry")
                    self.perform(#selector(ABModelCloudKit.publicSave(_:)), with: nil, afterDelay:retryAfterValue)
                }
                return
            }
            self.record = record
            self.recordId = record.recordID
            OperationQueue.main.addOperation({ () -> Void in
                error != nil ? ABModel.errorPrint(value: "public save error\(error)") : ()
                completion?(record, error as NSError?)
            })
        }
        CloudKitManager.publicDB.add(saveOp)
    }

    open func saveBulk(_ records: [CKRecord], completion: (() -> Void)?) {
        var rec = records
        rec.append(self.toRecord())

        let saveOp = CKModifyRecordsOperation(recordsToSave: rec, recordIDsToDelete: nil)
        saveOp.savePolicy = .allKeys
        saveOp.modifyRecordsCompletionBlock = ABModelCloudKit.mRecordCompletionBlock(saveOp: saveOp,
                                                                                     completion: completion)
        saveOp.perRecordCompletionBlock = { (record, error) in
            guard error == nil else {
                ABModel.errorPrint(value:"save bulk error \(error)")
                return
            }
            ABModel.dPrint(value:"save bulk \(record)")
        }
        CloudKitManager.publicDB.add(saveOp)
    }

    open class func mRecordCompletionBlock(saveOp: CKModifyRecordsOperation,
                                           completion: (() -> Void)?) -> ((_ records: [CKRecord]?,
        _ recordsId: [CKRecordID]?,
        _ error: Error?) -> Void)? {
            return { (records: [CKRecord]?, recordsId: [CKRecordID]?, error: Error?) in
                guard error == nil else {
                    ABModel.errorPrint(value:"records completion block error \(error)")

                    if let error = error as? NSError {
                        let errorCode = CKError.Code.init(rawValue: error.code)!

                        switch errorCode {
                        case .zoneBusy, .requestRateLimited:
                            if let retryAfter = error.userInfo[CKErrorRetryAfterKey] as? NSNumber {
                                let retrySave = CKModifyRecordsOperation(recordsToSave: saveOp.recordsToSave,
                                                                         recordIDsToDelete: saveOp.recordIDsToDelete)
                                retrySave.perRecordCompletionBlock = saveOp.perRecordCompletionBlock
                                retrySave.modifyRecordsCompletionBlock = mRecordCompletionBlock(saveOp: retrySave,
                                                                                                completion: completion)
                                retrySave.savePolicy = .allKeys
                                DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(retryAfter), execute: {
                                    if !retrySave.isFinished {
                                        CloudKitManager.publicDB.add(retrySave)
                                    }
                                })
                            }
                            break
                        case .serverRejectedRequest:
                            break
                        case .partialFailure:
                            let itemID = error.userInfo[CKPartialErrorsByItemIDKey]
                            ABModel.dPrint(value: itemID)
                            OperationQueue.main.addOperation({ () -> Void in
                                ABModel.errorPrint(value:"partial failure \(error)")
                                if ABModel.debug, let itemID = itemID as? [AnyHashable: Any] {
                                    for (key, value) in itemID {
                                        ABModel.dPrint(value:"key : \(key),  value : \(value)")
                                    }
                                }
                            })
                            break
                        default:
                            OperationQueue.main.addOperation({ () -> Void in
                                ABModel.errorPrint(value:"other \(error)")
                            })
                            break
                        }
                    }
                    return
                }
                OperationQueue.main.addOperation({ () -> Void in
                    completion?()
                })
            }
    }

    open class func saveBulk(_ records: [CKRecord], completion: (() -> Void)?) {
        let saveOp: CKModifyRecordsOperation = {
            $0.savePolicy = .allKeys
            $0.modifyRecordsCompletionBlock = mRecordCompletionBlock(saveOp: $0, completion: completion)
            $0.perRecordCompletionBlock = { (record, error) in
                guard error == nil else {
                    ABModel.errorPrint(value:"save bulk error \(error)")
                    return
                }
                ABModel.dPrint(value: "save bulk \(record)")
            }
            return $0
        }(CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil))
        CloudKitManager.publicDB.add(saveOp)
    }

    open func refresh<T: ABModelCloudKit>(_ completion:((_ updatedObj: T?) -> Void)? = nil) {
        CloudKitManager.publicDB.fetch(withRecordID: self.recordId) { (record, error) -> Void in
            guard let record = record else {
                ABModel.errorPrint(value: error)
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

    open func privateSave(_ completion:((_ record: CKRecord?, _ error: Error?) -> Void)? = nil) {
        CloudKitManager.privateDB.save(self.toRecord(), completionHandler: { (record, error) -> Void in
            if error != nil {
                ABModel.errorPrint(value:error)
            }
            completion?(record, error)
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
            } else {
                self.record.setObject(val, forKey: key)
            }
        }
        return record
    }

    open class func getRecord(_ predicateFormat: String,
                              completion: ((_ record: CKRecord?, _ error: NSError?) -> Void)? = nil) {
        let query = CKQuery(recordType: self.recordType(), predicate: NSPredicate(format: predicateFormat,
                                                                                  argumentArray: nil))
        CloudKitManager.publicDB.perform(query, inZoneWith: nil) { (records, error) -> Void in
            guard let records = records, let first = records.first else {
                OperationQueue.main.addOperation({ () -> Void in
                    ABModel.errorPrint(value:error)
                    completion?(nil, error as NSError?)
                })
                return
            }
            OperationQueue.main.addOperation({ () -> Void in
                ABModel.errorPrint(value:error)
                completion?(first, error as NSError?)
            })
        }
    }

    open func remove() {
        let deleteOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [self.recordId])
        deleteOp.perRecordCompletionBlock = {(record, error) in
            ABModel.errorPrint(value:error)
        }
        CloudKitManager.publicDB.add(deleteOp)
    }

    open class func removeRecordId(_ record: CKRecordID) {
        let deleteOp = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [record])
        deleteOp.perRecordCompletionBlock = {(record, error) in
            ABModel.errorPrint(value:error)
        }
        CloudKitManager.publicDB.add(deleteOp)
    }

    open func getReferences<T: ABModelCloudKit>(_ references: [CKReference],
                            completion:((_ results: [T], _ error: NSError?) -> Void)? = nil,
                            perRecordCompletion: ((_ result: T?, _ error: NSError?) -> Void)? = nil) {
        var results = [T]()
        let refs = references.map({ (reference) -> CKRecordID in
            reference.recordID
        })
        let op = CKFetchRecordsOperation(recordIDs: refs)
        op.queuePriority = .veryHigh
        if let completion = completion {
            op.fetchRecordsCompletionBlock = { (recordDictionary, error) in
                guard let recordDictionary = recordDictionary else {
                    ABModel.errorPrint(value:"get ref record Dico error \(error)")
                    completion([], nil)
                    return
                }
                guard error == nil else {
                    ABModel.errorPrint(value:"get ref error \(error)")
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
                    ABModel.errorPrint(value:"get ref error \(error)")
                    perRecordCompletion(nil, error as? NSError)
                    return
                }
                guard let recordId = recordId, let record = record else {
                    OperationQueue.main.addOperation({ () -> Void in
                        perRecordCompletion(nil, error as NSError?)
                    })
                    return
                }
                let object = T(record:record, recordId:recordId)
                OperationQueue.main.addOperation({ () -> Void in
                    perRecordCompletion(object, error as NSError?)
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
    open static var isAvailable: Bool = false

    open class func userAlreadyConnectThisDevice() -> Bool {
        return UserDefaults().bool(forKey: "userConnect")
    }

    open class func availability(_ completion:((_ available: Bool, _ alert: UIAlertController?) -> Void)? = nil) {
        CloudKitManager.container.accountStatus { (status, error) -> Void in
            let title: String
            let message: String
            switch status {
            case .available:
                CloudKitManager.isAvailable = true
                OperationQueue.main.addOperation({ () -> Void in
                    completion?(true, nil)
                })
                return
            case .couldNotDetermine :
                title = "An error occured while connecting to your iCloud account"
                message = error!.localizedDescription
                break
            case .noAccount:
                CloudKitManager.isAvailable = false
                title = "iCloud account required"
                message = "To use this app you need to be connected to your iCloud account"
                break
            case .restricted :
                CloudKitManager.isAvailable = false
                title = "iCloud capabilities required"
                message = "To use this app you need to be connected " +
                "to your iCloud account and set iCloud Drive enable"
                break
            }
            OperationQueue.main.addOperation({ () -> Void in
                let alert = UIAlertController(title: title,
                                              message: message,
                                              preferredStyle: UIAlertControllerStyle.alert)
                completion?(false, alert)
            })
        }
    }
}
