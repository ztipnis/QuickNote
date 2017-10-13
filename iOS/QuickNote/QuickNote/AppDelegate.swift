//
//  AppDelegate.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/10/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import UIKit
import QNConnect
import YapDatabase
import slideOutMenu
import QuickNote_Database
import IQKeyboardManagerSwift


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var conn:QNConnection?
    var database: QNDatabase?
    var notes:[QNNote] = []{
        didSet{
            print("didChange")
        }
    }
    var noteVC:ADsource?
    lazy var YDCK:YapDatabaseCloudKit = {

        let recordBlock = YapDatabaseCloudKitRecordHandler.withObjectBlock({
            (transaction, inOutRecord, recordInfo, collection, key, object) in
            guard let note = object as? QNNote else {
                return
            }
            recordInfo.databaseIdentifier = "private"
            var record:CKRecord? = inOutRecord?.pointee ?? nil

            if((record != nil) && !note.didChange && !(recordInfo.keysToRestore != nil)){
                return
            }

            var isNewRecord = false
            if(record == nil){
                //let cont = CKContainer(identifier: "iCloud.com.zachal.QuickNote")
                let zoneID = CKRecordZoneID(zoneName: "notes", ownerName: CKCurrentUserDefaultName)
                let recordID = CKRecordID(recordName: note.uuid.uuidString, zoneID: zoneID)
                record = CKRecord(recordType: "note", recordID: recordID)
                inOutRecord?.pointee = record!
                recordInfo.databaseIdentifier = "private"
                isNewRecord = true
            }
            var cloudKeys:[Any]? = nil
            if(recordInfo.keysToRestore != nil){
                cloudKeys = recordInfo.keysToRestore
            } else if(isNewRecord){
                cloudKeys = note.cloudKeys().allKeys
            }else {
                cloudKeys = note.changedKeys
            }
            for singleKey in cloudKeys ?? [] {
                guard let key = singleKey as? String else{
                    break
                }
                if (key == "data"){
                    let noteData = note.attribData
                    let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let tempFile = tempDir.appendingPathComponent((note.uuid.uuidString), isDirectory: false)
                    do {
                        try note.attribData.write(to: tempFile!, options: .atomic)
                        let val = CKAsset(fileURL: (tempFile?.absoluteURL)!)
                        record?.setObject(val, forKey: key)
                        
                    } catch {
                        continue
                    }
                }else{
                    guard let val = note.cloudKeys().value(forKey: key) as? CKRecordValue else{
                        return
                    }
                    record?.setObject(val, forKey: key)
                }
            }

        })
        let identifierBlock:YapDatabaseCloudKitDatabaseIdentifierBlock = { database in
            return CKContainer(identifier: "iCloud.com.zachal.QuickNote").privateCloudDatabase
        }

        let mergeBlock:YapDatabaseCloudKitMergeBlock = {
            (transaction, collection, key, remoteRecord, mergeInfo) in
            var remoteChangedKeys = [String]()
            if remoteRecord.recordType == "note" {
                guard let note = transaction.object(forKey: key ?? "", inCollection: collection ?? "") as? QNNote else {
                    return
                }
                for recKey in remoteRecord.allKeys() {
                    let localVal = note.cloudKeys().value(forKey: recKey) as AnyObject
                    let remoteVal = remoteRecord.value(forKey: recKey) as AnyObject
                    if (!(remoteVal === localVal)) {
                        if !note.changedKeys.contains(recKey) {
                            remoteChangedKeys.append(recKey)
                        }
                    }

                }
                let localChangedKeys = NSMutableSet(array: mergeInfo.pendingLocalRecord?.changedKeys() ?? [String]())
                for remKey in remoteChangedKeys {
                    if remKey == "data" {
                        let val = remoteRecord.value(forKey: remKey) as! CKAsset
                        do {
                            let data = try Data(contentsOf: val.fileURL)
                            note.ckSetVal(to: data, key: remKey)
                            localChangedKeys.remove(remKey)
                        } catch {
                            continue
                        }
                    }else{
                        let val = remoteRecord.value(forKey: remKey)
                        note.ckSetVal(to: val, key: remKey)
                        localChangedKeys.remove(remKey)
                    }                }
                for locKey in localChangedKeys {
                    if ((locKey as? String) ?? "") == "data" {

                    }else{
                        let val = mergeInfo.pendingLocalRecord?.value(forKey: locKey as? String ?? "")
                        mergeInfo.updatedPendingLocalRecord.setObject(val as? CKRecordValue ?? nil, forKey: locKey as? String ?? "")
                    }
                }
                transaction.setObject(note, forKey: key ?? "", inCollection: collection)

            }
        }

        let errorBlock:YapDatabaseCloudKitOperationErrorBlock = {
            (databaseID, opError) in
            print(databaseID)
            print(opError)
            if (opError as! CKError).code == CKError.Code.serverRecordChanged {
                let recordID1 = (opError as! CKError).clientRecord?.recordID
                print("record: \(recordID1)")
                //let recordID2 = (opError as! CKError).ancestorRecord?.recordID
            }else if (opError as! CKError).code == CKError.Code.partialFailure {
                for (id, error) in (opError as! CKError).partialErrorsByItemID! {
                    print("Error \(error) for \(id)")
                    if (error as! CKError).code == CKError.Code.serverRecordChanged {
                        self.database?.getConnection(type: .async).asyncReadWrite({
                            trans in
                            //trans.ext("yd") as! YapDatabaseExtension
                            for key in trans.allKeys(inCollection: "Notes"){
                                print(key)
                            }
                            (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.detachRecord(forKey: (id as! CKRecordID).recordName, inCollection: "Notes", wasRemoteDeletion: true, shouldUploadDeletion: false)
                            trans.removeObject(forKey: (id as! CKRecordID).recordName, inCollection: "Notes")
                        }, completionBlock: {
                            for (index, note) in self.notes.enumerated() {
                                print("\(index) : \(note.uuid.uuidString)")
                                if note.uuid.uuidString.contains((id as! CKRecordID).recordName) {
                                    self.notes.remove(at: index)
                                }
                            }
                            //self.noteView.reloadData()
                            self.noteVC?.reload()
                            self.YDCK.resume()
                        })
                    }
                }
            }
            //self.YDCK.resume()
            
        }
        return YapDatabaseCloudKit(recordHandler: recordBlock, merge: mergeBlock, operationErrorBlock: errorBlock, databaseIdentifierBlock: identifierBlock, versionTag: "1", versionInfo: nil, options: nil)
    }()

    func saveNote(note: Int){
        //appDelegate.database?.getConnection(type: .main).asy
        database?.getConnection(type: .main).asyncReadWrite({ transRead in
            transRead.setObject(self.notes[note], forKey: self.notes[note].uuid.uuidString, inCollection: "Notes")
        })
    }

    func saveNoteLiteral(note: QNNote){
        database?.getConnection(type: .main).asyncReadWrite({ transRead in
            transRead.setObject(note, forKey: note.uuid.uuidString, inCollection: "Notes")
        })
    }


    func getApplicationSupportURL() -> NSURL {
        do {
            return try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) as NSURL
        } catch {
            fatalError("Failed to get URL for application support directory")
        }
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        IQKeyboardManager.sharedManager().enable = true
        conn = QNConnection.init()
        guard let databasePath = getApplicationSupportURL().appendingPathComponent("QuickNote.sqlite")?.path else {
            fatalError("Failed to get database path")
        }
        let postSanitizer:YapDatabasePostSanitizer = {
            (collection, key, object) in
            guard let sanitized = object as? QNNote else{
                return
            }
            sanitized.changedKeys = []
        }
        let localDB = YapDatabase(path: databasePath, serializer: nil, deserializer: nil, preSanitizer: nil, postSanitizer: postSanitizer, options: nil)
        localDB.asyncRegister(YDCK, withName: "ck", completionBlock: {
            ready in
            if(!ready) {
                print("Error loading CloudKit")
            }else{
                print("CloudKit Extension loaded successfully")
            }
        })
        //let localDB = YapDatabase(path: databasePath)
        database = QNDatabase(database: localDB)
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        noteVC?.saveAll()
        for note in notes{
            saveNoteLiteral(note: note)
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        noteVC?.saveAll()
        for note in notes{
            saveNoteLiteral(note: note)
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        noteVC?.loadAll()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        noteVC?.loadAll()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        noteVC?.saveAll()
        for note in notes{
            saveNoteLiteral(note: note)
        }
    }


}

protocol ADsource {

    func saveAll()

    func loadAll()

    func reload()

}
