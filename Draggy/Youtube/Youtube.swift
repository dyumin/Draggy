//
//  Youtube.swift
//  Draggy
//
//  Created by El D on 17.03.2021.
//

import Cocoa

// safe to call from multiple threads, but python-related tasks will be performed in serial order
class Youtube {

    public static let shared = Youtube()

    private init() { // use shared
        let scriptsPath = Bundle.main.resourceURL!.appendingPathComponent("Scripts").path
        PythonRunner.shared.sync { () -> Void in
            Python.import("sys").path.append(scriptsPath)
        }
        YoutubeDL = PythonRunner.shared.sync {
            Python.import("youtube_dl").YoutubeDL
        }
        logger = PythonRunner.shared.sync {
            Python.import("Logger").Logger()
        }
    }

    private let YoutubeDL: PythonObject
    private let logger: PythonObject

    public func getID(_ video: URL) -> String? {
        PythonRunner.shared.sync {
            let params: Dictionary<PythonObject, PythonObject> = [
                "forceid": true
                , "quiet": true
                , "simulate": true
                , "logger": logger
            ]

            if YoutubeDL(params).download([video.absoluteString]) == 0 {
                return String(logger.lastMessage)
            }

            return nil
        }
    }
}
