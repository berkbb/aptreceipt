//
//  AppDelegate.swift
//  aptreceipt
//
//  Created by berkbb on 16.03.2022.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        lazy var windows = NSWindow()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
            if !flag {
                sender.windows.forEach { $0.makeKeyAndOrderFront(self) }
            }

            return true
        }
    
    
}

