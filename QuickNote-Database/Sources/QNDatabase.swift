//
//  QNDatabase.swift
//  QuickNote-Database
//
//  Created by Zachary A. Tipnis on 3/19/17.
//
//

import Foundation
import YapDatabase

public class QNDatabase {
    public enum connectionType {
        case main
        case background
        case async
        case worker(id:Int)
        var intValue : Int {
            switch self {
            case .main:
                return 0
            case .background:
                return 1
            case .async:
                return 2
            case .worker(id: let idNum):
                return 3+idNum
            }
        }
    }
    public init(database: YapDatabase) {
        do {
          try Connections.initShared(database: database)
        }catch{
            print("Couldn't connect to database: ", database)
            fatalError()
        }
    }
    public func getConnection(type: connectionType) -> YapDatabaseConnection{
        do{
            return try Connections.sharedConnection(id: type.intValue)
        }catch{
            print("Couldn't get get connection: ", type.intValue)
            fatalError()
        }
    }
    public func newWorker() -> Int {
        do {
            try Connections.newSharedConnection()
            return try Connections.count() - 4
        }catch{
            print("Couldn't create new worker")
            fatalError()
        }
    }
}
