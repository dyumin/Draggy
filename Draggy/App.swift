//
//  App.swift
//  Draggy
//
//  Created by El D on 20.02.2021.
//

import Cocoa

class App : NSApplication
{
    let _delegate = AppDelegate()
    let SIGTERM_handler: DispatchSourceSignal = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
    
    override init() {
        super.init()
        
        signal(SIGTERM, SIG_IGN) // // Make sure the signal does not terminate the application.
        SIGTERM_handler.setEventHandler { [weak self] in
            App.shared.terminate(self)
        }
        SIGTERM_handler.resume()
        delegate = _delegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
