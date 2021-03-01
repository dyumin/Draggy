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
        if #available(OSX 10.14, *) {
            App.shared.appearance = NSAppearance(named: .darkAqua)
        }
        _ = DragSessionManager.shared // init shared instance
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            _ = RecentAppsManager.shared // open db connection
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        RecentAppsManager.shared.applicationWillTerminate() // disk write
    }
}

