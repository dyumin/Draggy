//
//  SimpleBundle.swift
//  Draggy
//
//  Created by El D on 27.02.2021.
//

import Cocoa

// Bundle class may fail if actual bundle was relocated; and all we need is path and typesafety
// Both NSURL and URL classes threat folders and files differently, folders get trailing slash in the representation, nonexistent folders treated as nonexistent files and dont get a trailing slash.
// May represent binary as well as bundle
class SimpleBundle: NSURL {
    
    init(_ url: URL) {
        super.init(fileURLWithPath: url.path)
    }
    
    init(_ bundle: Bundle) {
        super.init(fileURLWithPath: bundle.bundlePath)
    }
    
    init(_ path: String) {
        super.init(fileURLWithPath: path)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
    }
    
    var bundleURL: URL
    {
        get
        {
            self as URL
        }
    }
}
