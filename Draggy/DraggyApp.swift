//
//  DraggyApp.swift
//  Draggy
//
//  Created by El D on 20.02.2021.
//

import Cocoa

class DraggyApp : NSApplication
{
    let _delegate = AppDelegate()
    
    override init() {
        super.init()
        delegate = _delegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
