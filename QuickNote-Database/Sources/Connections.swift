//
//  Connection.swift
//  QuickNote-Database
//
//  Created by Zachary A. Tipnis on 3/19/17.
//
//

import Foundation
import YapDatabase

class Connections {
    private static var shared: Connections?
    private var main:[YapDatabaseConnection] = []
    class func initShared(database: YapDatabase) throws{
        if shared == nil {
            do {
                self.shared = try Connections(database: database)
            }catch let error{
                throw error
            }
        }else{
            throw errorTypes.sharedConnectionsAlreadySet
        }
    }
    class func clearShared() {
        self.shared = nil
    }

    static func sharedConnections() throws -> Connections {
        if let sharedConns = shared {
            return sharedConns
        }else{
            throw errorTypes.sharedConnectionsUninitilized
        }
    }

    static func newSharedConnection() throws{
        do{try sharedConnections().main.append(Database.newConnection())}catch let error{
            throw error
        }
    }

    static func sharedConnection(id: Int) throws -> YapDatabaseConnection {
        do{
            return try sharedConnections().main[id]
        }catch let error{
            throw error
        }
    }
    static func count() throws -> Int{
        do{
            return try sharedConnections().main.count
        }catch let error{
            throw error
        }
    }


    private init() throws {
        do {
            try main.append(Database.newConnection())
            try main.append(Database.newConnection())
            try main.append(Database.newConnection())
        }catch let error{
            throw error
        }

    }

    private init(database: YapDatabase) throws {
        do{
            try Database.setSharedDatabase(database: database)
            try main.append(Database.newConnection())
            try main.append(Database.newConnection())
            try main.append(Database.newConnection())
        }catch let error{
            throw error
        }
    }
    
}
