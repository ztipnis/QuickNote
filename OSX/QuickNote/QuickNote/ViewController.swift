//
//  ViewController.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/10/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import Cocoa
import MultipeerConnectivity
import YapDatabase
import QuickNote_Database
import QNConnect
import CloudKit

class ViewController: NSViewController {

    let appDelegate = NSApp.delegate as! AppDelegate
    @IBOutlet var bottomVC: NSView!
    @IBAction func didClickInsertPicture(sender: AnyObject?) {
        conn.setupPeerIDAndSession(with: Host.current().localizedName!)
        conn.setupMCBrowser()
        conn.browser?.delegate = self
        presentViewControllerAsModalWindow(conn.browser!)
    }
    @IBAction func toggleLeftPanel(sender: AnyObject?){
        for i in vertDivider.subviews {
            if i == leftPart {
                i.isHidden = !(vertDivider.isSubviewCollapsed(i))
            }
        }
    }
    //let appDelegate = NSApplication.shared().delegate as! AppDelegate
     var database:QNDatabase?
    func getApplicationSupportURL() -> NSURL {
        do {
            return try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true) as NSURL
        } catch {
            fatalError("Failed to get URL for application support directory")
        }
    }
    @IBOutlet weak var vertDivider: NSSplitView!
    @IBOutlet weak var leftPart: NSView!
    @IBOutlet weak var rightPart: NSView!
    @IBOutlet weak var noteView: NSCollectionView!
    @IBOutlet weak var scroller: NSScrollView!
    @IBOutlet weak var topPart: NSView!
    @IBOutlet var mainTextView: NSTextView!
    @IBAction func didClickNewNote(sender: AnyObject){
        var title = "Hello World"
        let alert = NSAlert.init()
        alert.messageText = "Note title:"
        alert.addButton(withTitle: "Ok")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField.init(frame: NSRect.init(x: 0, y: 0, width: 200, height: 24))
        input.stringValue = ""
        alert.accessoryView = input
        let buttonval = alert.runModal()
        if (buttonval == NSAlertFirstButtonReturn){
            title = input.stringValue
        }else{
            return
        }
        var newNote = QNNote()
        if(!((mainTextView.textStorage?.string.isEmpty) ?? true) && (noteView.selectionIndexes.isEmpty)){
            let range = NSRange.init(location: 0, length: (mainTextView.textStorage?.length)!)
            newNote = QNNote(title: title, description: (mainTextView.textStorage?.string)!, with: mainTextView.rtfd(from: range)!)
        }else{
            noteView.deselectAll(nil)
            mainTextView.string = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
            let range = NSRange.init(location: 0, length: (mainTextView.textStorage?.length)!)
            newNote = QNNote(title: title, description: (mainTextView.textStorage?.string)!, with: mainTextView.rtfd(from: range)!)
        }
        noteArray.insert(newNote, at: 0)
        let range = NSRange.init(location: 0, length: (mainTextView.textStorage?.length)!)
        mainTextView.replaceCharacters(in: range, withRTFD: newNote.getRawValues().data)
        noteView.deselectAll(nil)
        noteView.reloadData()
        let index = [IndexPath.init(item: 0, section: 0)]
        noteView.item(at: index[0])?.textField?.stringValue = title
        noteView.selectItems(at: [IndexPath.init(item: 0, section: 0)], scrollPosition: .top)
    }
    
    @IBAction func didSelectOpenPhotoDialog(sender: AnyObject?){
        let destination = NSStoryboard(name: "Main", bundle: Bundle.main).instantiateController(withIdentifier: "photoModalDialog") as! openFileModal
        destination.delegate = self
        presentViewControllerAsModalWindow(destination)
    }
    var conn = QNConnection()
    var noteArray = [QNNote]()
    var selectedIndex:Int?
    var YDCK:YapDatabaseCloudKit?
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
                            for (index, note) in self.noteArray.enumerated() {
                                print("\(index) : \(note.uuid.uuidString)")
                                if note.uuid.uuidString.contains((id as! CKRecordID).recordName) {
                                    self.noteArray.remove(at: index)
                                }
                            }
                            self.noteView.reloadData()
                            self.YDCK?.resume()
                            self.noteView.reloadData()
                        })
                    }
                }
            }
            self.noteView.reloadData()



        }
        YDCK = {
            let recordBlock = YapDatabaseCloudKitRecordHandler.withObjectBlock({
                (transaction, inOutRecord, recordInfo, collection, key, object) in
                guard let note = object as? QNNote else {
                    return
                }
                var record:CKRecord? = inOutRecord?.pointee ?? nil
                recordInfo.databaseIdentifier = "private"
                if((record != nil) && !note.didChange && !(recordInfo.keysToRestore != nil)){
                    return
                }

                var isNewRecord = false
                if(record == nil){
                    //let defZID =
                    let zoneID = CKRecordZoneID(zoneName: "notes", ownerName: CKCurrentUserDefaultName)
                    let recordID = CKRecordID(recordName: note.uuid.uuidString, zoneID: zoneID)
                    record = CKRecord(recordType: "note", recordID: recordID)
                    inOutRecord?.pointee = record!
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
                        return
                    }
                    if (key == "data"){
                        let noteData = note.attribData
                        let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                        let tempFile = tempDir.appendingPathComponent((note.uuid.uuidString), isDirectory: false)
                        do {
                            try note.attribData.write(to: tempFile!, options: .atomic)
                        } catch {
                            continue
                        }
                        let val = CKAsset(fileURL: (tempFile?.absoluteURL)!)
                        record?.setObject(val, forKey: key)
                    }else{
                        guard let val = note.cloudKeys().value(forKey: key) as? CKRecordValue else{
                            return
                        }
                        record?.setObject(val, forKey: key)
                    }
                    //record?.setObject(val, forKey: key)
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
                        }
                    }
                    for locKey in localChangedKeys {
                        let val = mergeInfo.pendingLocalRecord?.value(forKey: locKey as? String ?? "")
                        mergeInfo.updatedPendingLocalRecord.setObject(val as? CKRecordValue ?? nil, forKey: locKey as? String ?? "")
                    }
                    transaction.setObject(note, forKey: key ?? "", inCollection: collection)
                    
                }
            }
            
            
            let YDCKExt = YapDatabaseCloudKit(recordHandler: recordBlock, merge: mergeBlock, operationErrorBlock: errorBlock, databaseIdentifierBlock: identifierBlock, versionTag: "1", versionInfo: nil, options: nil)
            return YDCKExt
            }()
        guard let databasePath = getApplicationSupportURL().appendingPathComponent("QuickNote.sqlite")?.path else {
            fatalError("Failed to get database path")
        }

        //print(databasePath)
        let postSanitizer:YapDatabasePostSanitizer = {
            (collection, key, object) in
            guard let sanitized = object as? QNNote else{
                return
            }
            sanitized.changedKeys = []
        }
        print(databasePath)
        let localDB = YapDatabase(path: databasePath, serializer: nil, deserializer: nil, preSanitizer: nil, postSanitizer: postSanitizer, options: nil)
        //prin
        YDCK?.suspend()
        YDCK?.suspend()
        YDCK?.suspend()
        localDB.asyncRegister(YDCK!, withName: "ck", completionBlock: {
            ready in

            if(!ready) {
                print("Error loading CloudKit")
            } else {
                print("CloudKit registration complete")
                self.setup()
            }
        })

        database = QNDatabase(database: localDB)

        print(CKCurrentUserDefaultName)
        view.wantsLayer = true
        noteView.register(noteCollectionItem.self, forItemWithIdentifier: "item")
        noteView.register(NSNib(nibNamed: "noteCollectionItem", bundle: Bundle.main), forItemWithIdentifier: "item")
        bottomVC.layer?.backgroundColor = CGColor(red: 255, green: 255, blue: 255, alpha: 0.5)
        
        let flowlayout = noteView.collectionViewLayout as! NSCollectionViewFlowLayout
        flowlayout.itemSize = NSSize(width: 100, height: 100)
        noteView.collectionViewLayout = flowlayout
        scroller.layer?.backgroundColor = NSColor.clear.cgColor
        scroller.backgroundColor = NSColor.clear
        scroller.drawsBackground = false
        noteView.allowsMultipleSelection = false
    }

    func saveNote(note: Int){
        print("save")
        print(self.YDCK?.suspendCount)
        database?.getConnection(type: .main).asyncReadWrite({ transRead in
            transRead.setObject(self.noteArray[note], forKey: self.noteArray[note].uuid.uuidString, inCollection: "Notes")
        })
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        database?.getConnection(type: .main).read({transRead in
            print(transRead)
            for key in transRead.allKeys(inCollection: "Notes") {
                if !self.noteArray.contains(transRead.object(forKey: key, inCollection: "Notes") as! QNNote) {
                    self.noteArray.append(transRead.object(forKey: key, inCollection: "Notes") as! QNNote)
                }
            }
        })
        noteView.reloadData()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        noteView.layer?.backgroundColor = NSColor.clear.cgColor
        noteView.backgroundView = NSView.init(frame: CGRect.zero)
        bottomVC.layer?.backgroundColor = CGColor(red: 255, green: 255, blue: 255, alpha: 0.5)
        // Do any additional setup after loading the view.
        database?.getConnection(type: .main).read({transRead in
            print(transRead)
            for key in transRead.allKeys(inCollection: "Notes") {
                if !self.noteArray.contains(transRead.object(forKey: key, inCollection: "Notes") as! QNNote) {
                    self.noteArray.append(transRead.object(forKey: key, inCollection: "Notes") as! QNNote)
                }
            }
        })
        //print(noteArray)
        //print(noteArray.count)
        noteView.reloadData()
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        noteView.deselectAll(self)
    }


    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    func setup(){
        let alert = NSAlert()
        alert.addButton(withTitle: "OK")
        alert.messageText = "Log in to iCloud"
        alert.informativeText = "An iCloud account is required sync notes to cloud."
        let db = database?.getConnection(type: .background)
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
                                alert.runModal()
                            }
                        } else if(ckErrorCode == CKError.partialFailure){
                            let partialError = NSDictionary(dictionary: error.userInfo)
                            let errorList = partialError.value(forKey: CKPartialErrorsByItemIDKey) as! NSDictionary
                            for perZoneError in errorList.objectEnumerator() {
                                let ckErrorCode1 = (perZoneError as! CKError).code
                                if ckErrorCode1 == CKError.notAuthenticated {
                                    DispatchQueue.main.async {
                                        alert.runModal()
                                    }
                                }
                            }
                        }
                        return
                    }
                    self.YDCK?.resume()
                    self.noteView.reloadData()
                    db?.readWrite({
                        trans in
                        trans.setObject(true, forKey: "hasZone", inCollection: "CK_DEFAULTS")
                    })
                }
                modifyZoneOp.allowsCellularAccess = true
                CKContainer(identifier: "iCloud.com.zachal.QuickNote").privateCloudDatabase.add(modifyZoneOp)
                self.noteView.reloadData()
            }else{
                self.YDCK?.resume()
                self.noteView.reloadData()
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
                    self.YDCK?.resume()
                    self.noteView.reloadData()
                    db?.readWrite({
                        trans in
                        trans.setObject(true, forKey: "hasSubscription", inCollection: "CK_DEFAULTS")
                    })
                }
                operation.allowsCellularAccess = true
                CKContainer(identifier: "iCloud.com.zachal.QuickNote").privateCloudDatabase.add(operation)
                self.noteView.reloadData()
            }else{
                self.YDCK?.resume()
                self.noteView.reloadData()
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
        var deletedIDs:NSMutableArray? = nil
        var changedRecords:NSMutableArray? = nil
        recFechOp.recordWithIDWasDeletedBlock = {
            recordID in
            if deletedIDs == nil {
                deletedIDs = NSMutableArray()
            }
            deletedIDs?.add(recordID)
        }
        recFechOp.recordChangedBlock = {
            record in

            if changedRecords == nil {
                changedRecords = NSMutableArray()
            }

            changedRecords?.add(record)
        }
        recFechOp.recordZoneFetchCompletionBlock = {
            (_zoneID, _token, _tokenData, moreComing, opError) in
            print ("yo")
            print(deletedIDs)
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
                        self.YDCK?.resume()
                        self.noteView.reloadData()
                    }
                    break handleError
                }
            }
            let hasChanges:Bool = {
                return (((deletedIDs?.count ?? 0) > 0) || ((changedRecords?.count ?? 0) > 0))
            }()
            if (!hasChanges && !moreComing) {
                db?.asyncReadWrite({
                    trans in
                    trans.setObject(_token, forKey: "lastServerKey", inCollection: "CK_DEFAULTS")
                })
                self.YDCK?.resume()
                self.noteView.reloadData()
            }else{
                db?.asyncReadWrite({
                    trans in
                    guard trans.ext("ck") is YapDatabaseCloudKitTransaction else { return }
                    print(deletedIDs)
                    for (delID) in (deletedIDs ?? NSMutableArray()) {
                        if delID is CKRecordID{
                            let ckDelID = delID as! CKRecordID
                            guard let collectionKeys = (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.collectionKeys(for: ckDelID, databaseIdentifier: nil) else { print("there was a problem");continue }
                            for ck in collectionKeys {
                                (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.detachRecord(forKey: ck.key,
                                                                                                   inCollection: ck.collection,
                                                                                                   wasRemoteDeletion: true,
                                                                                                   shouldUploadDeletion: false)
                                trans.removeObject(forKey: ck.key, inCollection: ck.collection)

                            }
                        }
                    }
                    for rec in (changedRecords ?? NSMutableArray()) {
                        if rec is CKRecord {
                            let ckRec = rec as! CKRecord
                            guard ckRec.recordType == "note" else {continue}
                            var changeTag:NSString? = nil
                            var hasMod = ObjCBool(false)
                            var hasDel = ObjCBool(false)
                            (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.getRecordChangeTag(&changeTag, hasPendingModifications: &hasMod, hasPendingDelete: &hasDel, for: ckRec.recordID, databaseIdentifier: nil)
                            print(hasDel.boolValue)
                            if changeTag != nil {
                                if changeTag?.isEqual(to: ckRec.recordChangeTag ?? "") ?? true{

                                } else {
                                    (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.merge(ckRec, databaseIdentifier: nil)

                                }
                            } else if (hasMod).boolValue {
                                (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.merge(ckRec, databaseIdentifier: nil)
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
                                (trans.ext("ck") as? YapDatabaseCloudKitTransaction)?.attach(ckRec, databaseIdentifier: nil, forKey: newNote.uuid.uuidString, inCollection: "Notes", shouldUploadRecord: true)
                                trans.setObject(newNote, forKey: newNote.uuid.uuidString, inCollection: "Notes")
                            }

                        }
                    }
                    trans.setObject(_token, forKey: "lastServerKey", inCollection: "CK_DEFAULTS")
                }, completionBlock: {
                    if !moreComing {
                        self.YDCK?.resume()
                        self.noteView.reloadData()
                    }
                })
            }
            
        }
        recFechOp.allowsCellularAccess = true
        CKContainer(identifier: "iCloud.com.zachal.QuickNote").privateCloudDatabase.add(recFechOp)
    }



}

extension ViewController:MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        conn.browser?.dismiss(nil)
    }
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        conn.browser?.dismiss(nil)
    }
}

extension ViewController:NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return((subview == leftPart) || subview.isEqual(to: topPart))
    }
    func splitView(_ splitView: NSSplitView, shouldCollapseSubview subview: NSView, forDoubleClickOnDividerAt dividerIndex: Int) -> Bool {
        return (subview.isEqual(to:leftPart) || subview.isEqual(to: topPart))
    }
/*    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        
    }*/
}

extension ViewController:NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return noteArray.count
    }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItem(withIdentifier: "item", for: indexPath)
        let note = noteArray[indexPath.item]
        item.textField?.stringValue = note.getRawValues().title
        guard let nextItem = item as? noteCollectionItem else {return item}
        nextItem.textField?.stringValue = note.getRawValues().title
        nextItem.descriptionField.stringValue = note.getRawValues().description
        return nextItem
    }
}

extension ViewController:NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        for indexPath in indexPaths {
            let note = noteArray[indexPath.item]
            selectedIndex = indexPath.item
            mainTextView.string = ""
            mainTextView.replaceCharacters(in: NSRange.init(location: 0, length: 0), withRTFD: note.getRawValues().data)
        }
    }
    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        for indexPath in indexPaths {
            let range = NSRange.init(location: 0, length: (mainTextView.textStorage?.length)!)
            noteArray[indexPath.item].setTitle(to: collectionView.item(at: indexPath)?.textField?.stringValue ?? "Hello World")
            noteArray[indexPath.item].setContent(to: mainTextView.rtfd(from: range)!)
            noteArray[indexPath.item].setDescription(to: (mainTextView.textStorage?.string)!)
            saveNote(note: indexPath.item)
            collectionView.reloadData()
        }
    }
}
extension ViewController:NSTextFieldDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        
        if (selectedIndex != nil){
            let range = NSRange.init(location: 0, length: (mainTextView.textStorage?.length)!)
            noteArray[selectedIndex!].setContent(to: mainTextView.rtfd(from: range)!)
            noteArray[selectedIndex!].setDescription(to: (mainTextView.textStorage?.string)!)
            noteView.reloadData()
        }
    }
}
extension ViewController:openFileModalDelegate {
    func onFileClose(image: NSImage) {
        //NSLog(localPath)
        let img = image
        if(img.size.width > 200) {
            let sFactor = 200/img.size.width
            let size = NSSize(width: img.size.width * sFactor, height: img.size.height * sFactor)
            img.size = size
        }
        let attachmentImg = NSTextAttachmentCell(imageCell: img)
        let attachment = NSTextAttachment()
        attachment.attachmentCell = attachmentImg
        let finVal = NSAttributedString(attachment: attachment)
        let range2 = mainTextView.selectedRange()
        mainTextView.insertText(finVal, replacementRange: range2)
    }
}
