//
//  CKMgr.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/29/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

class CKMgr{

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    func setup(completion: (()->())?){

        let alertController = UIAlertController(title: "Log in to iCloud", message: "An iCloud account is required sync notes to cloud.", preferredStyle: .alert)
        let okButton = UIAlertAction(title: "Ok", style: .default, handler: {alert in })
        alertController.addAction(okButton)

        let db = appDelegate.database?.getConnection(type: .background)
        db?.read({
            trans in
            if !trans.hasObject(forKey: "hasZone", inCollection: "CK_DEFAULTS"){
                let zone = CKRecordZone(zoneName: "notes")
                let modifyZoneOp = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)
                modifyZoneOp.modifyRecordZonesCompletionBlock = {
                    (savedZones, deletedZones, opError) in
                    guard (opError == nil) else{
                        guard let error = opError as? CKError else {
                            return
                        }
                        let ckErrorCode = error.code
                        if (ckErrorCode == CKError.notAuthenticated){
                            DispatchQueue.main.async {
                                self.appDelegate.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                            }
                        } else if(ckErrorCode == CKError.partialFailure){
                            let partialError = NSDictionary(dictionary: error.userInfo)
                            let errorList = partialError.value(forKey: CKPartialErrorsByItemIDKey) as! NSDictionary
                            for perZoneError in errorList.objectEnumerator() {
                                let ckErrorCode1 = (perZoneError as! CKError).code
                                if ckErrorCode1 == CKError.notAuthenticated {
                                    DispatchQueue.main.async {
                                        self.appDelegate.window?.rootViewController?.present(alertController, animated: true, completion: nil)
                                    }
                                }
                            }
                        }
                        return
                    }
                    self.appDelegate.YDCK.resume()
                    db?.readWrite({
                        trans in
                        trans.setObject(true, forKey: "hasZone", inCollection: "CK_DEFAULTS")
                    })
                }
                modifyZoneOp.allowsCellularAccess = true
                CKContainer(identifier: "iCloud.com.zachal.QuickNote").privateCloudDatabase.add(modifyZoneOp)
            }else{
                self.appDelegate.YDCK.resume()

            }
            if !trans.hasObject(forKey: "hasSubscription", inCollection: "CK_DEFAULTS"){

                let znID = CKRecordZoneID(zoneName: "notes", ownerName: CKCurrentUserDefaultName)
                //let subscription = CKSubscription(zoneID: znID, subscriptionID: "notes", options: CKSubscriptionOptions.init(rawValue: 0))
                let subscription = CKRecordZoneSubscription(zoneID: znID, subscriptionID: "notes")
                let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
                operation.modifySubscriptionsCompletionBlock = {
                    saved, deleted, errors in
                    guard errors == nil else{
                        return
                    }
                    self.appDelegate.YDCK.resume()
                    db?.readWrite({
                        trans in
                        trans.setObject(true, forKey: "hasSubscription", inCollection: "CK_DEFAULTS")
                    })
                }
                operation.allowsCellularAccess = true
                CKContainer(identifier: "iCloud.com.zachal.QuickNote").privateCloudDatabase.add(operation)
            }else{
                self.appDelegate.YDCK.resume()
            }
        })
        var prevServ:CKServerChangeToken?
        db?.read({ (trans) in
             prevServ = trans.object(forKey: "lastServerKey", inCollection: "CK_DEFAULTS") as? CKServerChangeToken ?? nil
        })
        let znID = CKRecordZoneID(zoneName: "notes", ownerName: CKCurrentUserDefaultName)
        let optns = CKFetchRecordZoneChangesOptions()
        optns.previousServerChangeToken = prevServ
        let recFechOp = CKFetchRecordZoneChangesOperation(recordZoneIDs: [znID], optionsByRecordZoneID: [znID : optns])
        let deletedIDs = NSMutableArray()
        let changedRecords = NSMutableArray()
        recFechOp.recordWithIDWasDeletedBlock = {
            recordID in
            deletedIDs.add(recordID)
        }
        recFechOp.recordChangedBlock = {
            record in
            changedRecords.add(record)
        }
        recFechOp.recordZoneFetchCompletionBlock = {
            (_zoneID, _token, _tokenData, moreComing, opError) in
            handleError : do{
                guard opError == nil else {

                    guard let cloudError = opError as? CKError else {
                        break handleError
                    }
                    let code = cloudError.code
                    if code == CKError.changeTokenExpired {
                        db?.asyncReadWrite({
                            trans in
                            trans.removeObject(forKey: "lastServerKey", inCollection: "CK_DEFAULTS")
                        })
                        self.appDelegate.YDCK.resume()
                        if(completion != nil){
                            completion!()
                        }
                    }
                    break handleError
                }
            }
            let hasChanges:Bool = {
                return ((deletedIDs.count > 0) || (changedRecords.count > 0))
            }()
            if (!hasChanges && !moreComing) {
                db?.asyncReadWrite({
                    trans in
                    trans.setObject(_token, forKey: "lastServerKey", inCollection: "CK_DEFAULTS")
                })
                self.appDelegate.YDCK.resume()
                if(completion != nil){
                    completion!()
                }
            }else{
                print(deletedIDs)
                db?.asyncReadWrite({
                    trans in
                    guard trans.ext("ck") is YapDatabaseCloudKitTransaction else { return }
                    for (delID) in deletedIDs {
                        if delID is CKRecordID{
                            let ckDelID = delID as! CKRecordID
                            guard let collectionKeys = (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.collectionKeys(for: ckDelID, databaseIdentifier: nil) else { continue }
                            for ck in collectionKeys {
                                (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.detachRecord(forKey: ck.key,
                                                                                                   inCollection: ck.collection,
                                                                                                   wasRemoteDeletion: true,
                                                                                                   shouldUploadDeletion: false)
                                trans.removeObject(forKey: ck.key, inCollection: ck.collection)

                            }
                        }
                    }
                    for rec in changedRecords {
                        if rec is CKRecord {
                            let ckRec = rec as! CKRecord
                            guard ckRec.recordType == "note" else {continue}
                            var changeTag:NSString? = nil
                            var hasMod = ObjCBool(false)
                            var hasDel = ObjCBool(false)
                            (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.getRecordChangeTag(&changeTag, hasPendingModifications: &hasMod, hasPendingDelete: &hasDel, for: ckRec.recordID, databaseIdentifier: nil)
                            if changeTag != nil {
                                if changeTag?.isEqual(to: ckRec.recordChangeTag ?? "") ?? true{

                                } else {
                                    (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.merge(ckRec, databaseIdentifier: "private")

                                }
                            } else if (hasMod).boolValue {
                                (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.merge(ckRec, databaseIdentifier: "private")
                            } else if (!hasDel.boolValue){
                                let newNote = QNNote()
                                //newNote.uuid = UUID(uuidString: ckRec.recordID.recordName)
                                for cckey in newNote.cloudKeys().allKeys {
                                    if (cckey as! String) == "data"{
                                        do {
                                            let val = ckRec.object(forKey: (cckey as! String)) as! CKAsset
                                            let data = try Data(contentsOf: val.fileURL)
                                            newNote.ckSetVal(to: data, key: cckey as! String)
                                        } catch {
                                            continue
                                        }
                                    }else{
                                        newNote.ckSetVal(to: ckRec.object(forKey: (cckey as! String)), key: cckey as! String)
                                    }
                                }
                                (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.attach(ckRec, databaseIdentifier: "private", forKey: newNote.uuid.uuidString, inCollection: "Notes", shouldUploadRecord: true)
                                trans.setObject(newNote, forKey: newNote.uuid.uuidString, inCollection: "Notes")
                            }

                        }
                    }
                    trans.setObject(_token, forKey: "lastServerKey", inCollection: "CK_DEFAULTS")
                }, completionBlock: {
                    if !moreComing {
                        self.appDelegate.YDCK.resume()
                        if(completion != nil){
                            completion!()
                        }
                    }
                })
            }

        }
        recFechOp.allowsCellularAccess = true
        CKContainer(identifier: "iCloud.com.zachal.QuickNote").privateCloudDatabase.add(recFechOp)
    }
}
