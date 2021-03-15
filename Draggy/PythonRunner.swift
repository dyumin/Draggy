//
//  PythonRunner.swift
//  Draggy
//
//  Created by El D on 15.03.2021.
//

import Dispatch
@_exported import PythonKit

// since python interpreter is single-threaded, use serial DispatchQueue
open class PythonRunner : DispatchQueue {
    public static let shared = { () -> PythonRunner in
        PythonLibrary.useVersion(3)
        return PythonRunner(label: "\(Bundle.main.bundleIdentifier!).PythonRunner")
    }()
}
