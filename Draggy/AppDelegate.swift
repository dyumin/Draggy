//
//  AppDelegate.swift
//  Draggy
//
//  Created by El D on 18.02.2021.
//

import Cocoa
import Foundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if #available(OSX 10.14, *) {
            App.shared.appearance = NSAppearance(named: .darkAqua)
        }
        
        do {
            // it is better to initialise in this order
            let dragSessionManager = DragSessionManager.shared // init shared instance
            let hudWindow = HudWindow.shared // init shared instance
            hudWindow.loadContentView()
            dragSessionManager.hudWindow = hudWindow.hudWindow
        }
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            _ = RecentAppsManager.shared // open db connection
        }

        // check for new version
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async {
            let newVersionPlistUrl = URL(string: "https://dyumin.github.io/projects/io.github.dyumin.Draggy/Info.plist")!
            var newVersionPlistRequest = URLRequest(url: newVersionPlistUrl)
            if #available(OSX 10.15, *) {
                newVersionPlistRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            } else {
                newVersionPlistRequest.cachePolicy = .reloadIgnoringLocalCacheData
            }
            let sessionDataTask = URLSession.shared.dataTask(with: newVersionPlistRequest) { (data, response, error) in
                guard error == nil, data != nil else {
                    print("Failed to check for new version, error: \(String(describing: error)), data: \(String(describing: data))")
                    return
                }

                if let data = data {
                    if let newVersionPlist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? Dictionary<String, Any> {
                        if let newVersionString = newVersionPlist["CFBundleShortVersionString"] as? String {
                            let lastCheckedVersion = UserDefaults.standard.string(forKey: "lastCheckedVersion")
                            if (lastCheckedVersion == newVersionString) { // suggest update to particular version only once
                                return
                            }
                            UserDefaults.standard.set(newVersionString, forKey: "lastCheckedVersion")
                            let currentVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

                            if (currentVersion.compare(newVersionString, options: .numeric) == .orderedAscending) { // warning: works incorrectly for 1.0.0 and 1.0 pairs and so on
                                DispatchQueue.main.async {
                                    let newVersionSheet = NSAlert.init()

                                    newVersionSheet.messageText = NSLocalizedString("newVersionSheet_newVersionAvailable", comment: "")

                                    newVersionSheet.addButton(withTitle: NSLocalizedString("newVersionSheet_download_button", comment: ""))
                                    newVersionSheet.addButton(withTitle: NSLocalizedString("newVersionSheet_close_button", comment: ""))

                                    if (newVersionSheet.runModal() == .alertFirstButtonReturn) {
                                        NSWorkspace.shared.open(URL(string: "https://github.com/dyumin/Draggy/releases")!)
                                    }
                                }
                            }
                        }
                    } else {
                        print("Failed to check for new version: data serialisation failed for data: \(data)")
                    }
                }
            }
            sessionDataTask.resume()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        RecentAppsManager.shared.applicationWillTerminate() // disk write
    }
}

