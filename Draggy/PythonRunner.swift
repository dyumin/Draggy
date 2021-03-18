//
//  PythonRunner.swift
//  Draggy
//
//  Created by El D on 15.03.2021.
//

import Dispatch
@_exported import PythonKit

fileprivate var gc: PythonObject? = nil

// since python interpreter is single-threaded, use serial DispatchQueue
open class PythonRunner : DispatchQueue {
    public static let shared = { () -> PythonRunner in
        PythonLibrary.useVersion(3)
        
        let queue = PythonRunner(label: "\(Bundle.main.bundleIdentifier!).PythonRunner")
        queue.sync {
            gc = Python.import("gc")
        }
        
        return queue
    }()
    
    public func runGC() {
        async {
            gc!.collect()
        }
    }
}
