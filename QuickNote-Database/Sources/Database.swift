//
//  Database.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/15/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import Foundation
import YapDatabase

public enum errorTypes: Error {
    case sharedDatabaseAlreadySet
    case sharedConnectionsAlreadySet
    case sharedDatabaseUninitilized
    case sharedConnectionsUninitilized
}

class Database {
    private static var sharedInstance: Database?

    // Set Database Instance (helper method, just calls init)
    class func setSharedDatabase(database: YapDatabase) throws {
        if sharedInstance == nil {
            self.sharedInstance = Database(database: database)
        }else{
            throw errorTypes.sharedDatabaseAlreadySet
        }
    }

    // Clear Database Instance
    class func clearSharedInstance() {
        sharedInstance = nil
    }

    // Get Database Instance
    static func sharedDatabase() throws -> Database {
        if let sharedInstance = sharedInstance {
            return sharedInstance
        } else {
            throw errorTypes.sharedDatabaseUninitilized
        }
    }

    static func newConnection() throws -> YapDatabaseConnection {
        do {
            return try sharedDatabase().database.newConnection()
        }catch let error{
            throw error
        }
    }

    static func registerExtension(view: YapDatabaseExtension, withName name: String) throws {
        do{
            try sharedDatabase().database.register(view, withName: name)
        } catch let error {
            throw error
        }
    }

    private let database: YapDatabase

    // Initialize Database
    private init(database: YapDatabase) {
        self.database = database
    }
}
