//
//  PythonRunner.swift
//  Draggy
//
//  Created by El D on 15.03.2021.
//

import Dispatch
@_exported import PythonKit


// since python interpreter is single-threaded, use serial DispatchQueue
open class PythonRunner {
    public static let shared = PythonRunner()

    private init() {
        PythonLibrary.useVersion(3)
        gc = queue.sync {
            Python.import("gc")
        }
    }

    internal let queue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).PythonRunner")
    private let gc: PythonObject

    public func sync<T>(execute work: () throws -> T) rethrows -> T {
        try queue.sync(execute: work)
    }

    public func async(group: DispatchGroup? = nil, qos: DispatchQoS = .unspecified, flags: DispatchWorkItemFlags = [], execute work: @escaping @convention(block) () -> Void) {
        queue.async(group: group, qos: qos, flags: flags, execute: work)
    }

    public func runGC() {
        queue.async {
            self.gc.collect()
        }
    }
}
