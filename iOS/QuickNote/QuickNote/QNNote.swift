//
//  QNNote.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/11/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import Foundation
import CloudKit

class QNNote: NSObject, NSCoding {

    public var title:String {
        didSet{
            didChange = true
            self.changedKeys.append("title")
            dateLastChanged = NSDate()
        }
    }
    public var attribData:Data {
        didSet{
            didChange = true
            self.changedKeys.append("data")
            dateLastChanged = NSDate()
        }
    }
    public var descriptionString:String {
        didSet{
            didChange = true
            self.changedKeys.append("desc")
            dateLastChanged = NSDate()
        }
    }
    public var uuid:UUID {
        didSet{
            didChange = true
            self.changedKeys.append("id")
            dateLastChanged = NSDate()
        }
    }
    public var didChange:Bool = false
    public var dateLastChanged = NSDate()

    public func cloudKeys() -> NSDictionary {
        let dictArray:[String: CKRecordValue] =
            ["id":NSString(string:uuid.uuidString), "title":NSString(string: title), "data":NSData(data: attribData), "desc":NSString(string: descriptionString)]
        return NSDictionary(dictionary: dictArray)

    }

    public var changedKeys:[String] = []

    override init(){

        self.title = ""
        self.descriptionString = ""
        self.attribData = Data()
        self.uuid = UUID()
    }

    required init(coder decoder: NSCoder) {
        self.title = decoder.decodeObject(forKey: "title") as! String
        self.descriptionString = decoder.decodeObject(forKey: "description") as! String
        self.attribData = decoder.decodeObject(forKey: "attribData") as! Data
        self.uuid = decoder.decodeObject(forKey: "uuid") as! UUID
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.title, forKey: "title")
        aCoder.encode(self.descriptionString, forKey: "description")
        aCoder.encode(self.attribData, forKey: "attribData")
        aCoder.encode(self.uuid, forKey: "uuid")
    }

    init(title: String, description:String, with content: Data){

        self.title = title
        self.attribData = content
        self.descriptionString = description
        self.uuid = UUID()
    }

    func setTitle(to title: String) {

        self.title = title
    }


    func setContent(to content:Data){

        self.attribData = content
    }

    func setDescription(to description: String) {
        self.descriptionString = description
    }

    func getRawValues() -> (title: String, data: Data, description: String, id: UUID){

        return(self.title, self.attribData, self.descriptionString, self.uuid)
    }

    func ckSetVal(to newVal:Any?, key: String){
        guard let finVal = newVal else{
            return
        }
        switch key {
        case "id" :
            self.uuid = UUID(uuidString: (finVal as! String))!
        case "title":
            self.setTitle(to: finVal as! String)
        case "data":
            self.attribData = finVal as! Data
        case "desc":
            self.descriptionString = finVal as! String
        default:
            break
            
        }
    }
    
    
    
}
