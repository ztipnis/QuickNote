//
//  AppDelegate.swift
//  QuickNote
//
//  Created by Zachary A. Tipnis on 3/10/17.
//  Copyright © 2017 zachal. All rights reserved.
//

import Cocoa
import YapDatabase
import QuickNote_Database

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

   

    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if(!flag){
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        return true
    }


}

