//
//  AppDelegate.swift
//  Draggy
//
//  Created by El D on 18.02.2021.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        _ = DragSessionManager.shared // init shared instance
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        RecentAppsManager.shared.applicationWillTerminate() // disk write
    }
}

