//
//  Youtube.swift
//  Draggy
//
//  Created by El D on 17.03.2021.
//  https://developer.apple.com/forums/thread/655343 - thoughts on dispatch_get_current_queue
//

import Cocoa

enum DownloadStatus: String, RawRepresentable {
    case downloading
    case error
    case finished
    case unknown
}

/**
 entries:
 * status: One of "downloading", "error", or "finished".
           Check this first and ignore unknown values.
 
 If status is one of "downloading", or "finished", the
 following properties may also be present:
 * filename: The final filename (always present)
 * tmpfilename: The filename we're currently writing to
 * downloaded_bytes: Bytes on disk
 * total_bytes: Size of the whole file, None if unknown
 * total_bytes_estimate: Guess of the eventual file size,
                         None if unavailable.
 * elapsed: The number of seconds since download started.
 * eta: The estimated time in seconds, None if unknown
 * speed: The download speed in bytes/second, None if
          unknown
 * fragment_index: The counter of the currently
                   downloaded video fragment.
 * fragment_count: The number of fragments (= individual
                   files that will be merged)
 
 Progress hooks are guaranteed to be called at least once
 (with status "finished") if the download is successful.
 */
struct progress_hook_dictionary {
    let status: DownloadStatus
    let filename: URL?
    let tmpfilename: URL?
    let downloaded_bytes: UInt64
    let total_bytes: UInt64?
    let total_bytes_estimate: UInt64?
    let elapsed: TimeInterval
    let eta: TimeInterval?
    let speed: Double
//    let fragment_index
//    let fragment_count

    init?(from dictionary1: PythonObject) {

        guard let progress = Dictionary<String, PythonObject>(dictionary1) else {
            return nil
        }

        status = { () -> DownloadStatus in
            guard let status = progress["status"], let statusEnum = DownloadStatus.init(rawValue: String(status)!)
                    else {
                return .unknown
            }
            return statusEnum
        }()

        filename = { () -> URL? in
            guard let filename = progress["filename"]
                    else {
                return nil
            }
            return URL(fileURLWithPath: String(filename)!)
        }()

        tmpfilename = { () -> URL? in
            guard let tmpfilename = progress["tmpfilename"]
                    else {
                return nil
            }
            return URL(fileURLWithPath: String(tmpfilename)!)
        }()

        downloaded_bytes = { () -> UInt64 in
            guard let downloaded_bytes = progress["downloaded_bytes"]
                    else {
                return 0
            }
            return UInt64(downloaded_bytes) ?? 0
        }()


        total_bytes = { () -> UInt64? in
            guard let total_bytes = progress["total_bytes"]
                    else {
                return nil
            }
            return UInt64(total_bytes)
        }()

        total_bytes_estimate = { () -> UInt64? in
            guard let total_bytes_estimate = progress["total_bytes_estimate"]
                    else {
                return nil
            }
            return UInt64(total_bytes_estimate)
        }()

        elapsed = { () -> TimeInterval in
            guard let elapsed = progress["elapsed"]
                    else {
                return 0
            }
            return TimeInterval(elapsed) ?? 0
        }()

        eta = { () -> TimeInterval? in
            guard let eta = progress["eta"]
                    else {
                return nil
            }
            return TimeInterval(eta)
        }()

        speed = { () -> Double in
            guard let speed = progress["speed"]
                    else {
                return 0
            }
            return Double(speed) ?? 0
        }()
    }
}

// safe to call from multiple threads, but python-related tasks will be performed in serial order
// so be careful not to cause any deadlocks
// Implementation design tries its best not to expose internal PythonRunner.shared queue and/or any PythonObjects to its users
class Youtube {

    public static let shared = Youtube()

    private init() { // use shared
        let scriptsPath = Bundle.main.resourceURL!.appendingPathComponent("Scripts").path
        (YoutubeDL, ProgressWrapper, logger) = {
            PythonRunner.shared.sync {
                Python.import("sys").path.append(scriptsPath)
                return (Python.import("youtube_dl").YoutubeDL, Python.import("ProgressWrapper").ProgressWrapper, Python.import("Logger").Logger())
            }
        }()
    }

    private let YoutubeDL: PythonObject
    private let ProgressWrapper: PythonObject
    private let logger: PythonObject
    private let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!

    // --get-id
    public func getID(_ video: URL) -> String? {
        getID(video, PythonRunner.shared.queue)
    }

    // --get-id
    private func getID(_ video: URL, _ queue: DispatchQueue? = nil) -> String? {
        let work = { [self] () -> String? in
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

        if let queue = queue {
            return queue.sync(execute: work)
        } else {
            return work()
        }
    }

    // --get-filename
    public func getFilename(_ video: URL) -> String? {
        getFilename(video, PythonRunner.shared.queue)
    }

    // --get-filename
    private func getFilename(_ video: URL, _ queue: DispatchQueue? = nil) -> String? {
        let work = { [self] () -> String? in
            let params: Dictionary<PythonObject, PythonObject> = [
                "forcefilename": true
                , "quiet": true
                , "simulate": true
                , "logger": logger
                , "outtmpl": "%(id)s.%(ext)s"
            ]

            if YoutubeDL(params).download([video.absoluteString]) == 0, let name = String(logger.lastMessage), !name.isEmpty {
                return name
            }

            return nil
        }

        if let queue = queue {
            return queue.sync(execute: work)
        } else {
            return work()
        }
    }

    var progressMap = Dictionary<PythonObject, Progress>()

    private func onProgressReported(_ progressWrapper: PythonObject) {
        let swiftProgress = progressMap[progressWrapper]!
        guard let progress = progress_hook_dictionary(from: progressWrapper.progress) else {
            assert(false)
            return
        }

        DispatchQueue.main.async {
            swiftProgress.estimatedTimeRemaining = progress.eta
            if swiftProgress.fileURL == nil {
                swiftProgress.fileURL = progress.filename
            }

            // set this before setting totalUnitCount and completedUnitCount since they affect swiftProgress.isFinished
            if progress.status == .finished {
                swiftProgress.fileCompletedCount = (swiftProgress.fileCompletedCount == nil) ? 1 : swiftProgress.fileCompletedCount! + 1
            }

            swiftProgress.totalUnitCount = Int64(progress.total_bytes ?? 0)
            let completedUnitCount = { () -> Int64 in
                if progress.downloaded_bytes == 0, progress.status != .downloading {
                    return swiftProgress.totalUnitCount // mark swiftProgress as finished // doest work if both totalUnitCount an completedUnitCount are zero
                }
                return Int64(progress.downloaded_bytes)
            }()

            if swiftProgress.totalUnitCount != completedUnitCount { // file operations still pending after completion notification, set isFinished after YoutubeDL return
                swiftProgress.completedUnitCount = completedUnitCount
            }
        }
    }

    @discardableResult
    public func download(_ video: URL) -> Progress {

        let progress = Progress()
        progress.fileOperationKind = .downloading
        progress.fileTotalCount = 1

        PythonRunner.shared.async { [self] in

            let progressWrapper = ProgressWrapper(PythonObject({ progressWrapper in
                Youtube.shared.onProgressReported(PythonObject(progressWrapper))
            }))

            progressMap[progressWrapper] = progress // calculates python hash

            let filePath = { () -> PythonObject in
                if NSClassFromString("XCTest") != nil { // not reliable, but will do
                    return URL(string: "/tmp")!.appendingPathComponent("%(id)s.%(ext)s").path.pythonObject
                }
                return downloadsDir.appendingPathComponent("%(id)s.%(ext)s").path.pythonObject
            }()

            let params: Dictionary<PythonObject, PythonObject> = [
                "outtmpl": filePath
                , "quiet": true
                , "progress_hooks": [progressWrapper]
            ]

            YoutubeDL(params).download([video.absoluteString])

            let progress = progressMap.removeValue(forKey: progressWrapper)! // calculates python hash
            DispatchQueue.main.async {
                progress.completedUnitCount = progress.totalUnitCount
            }
            
//            PythonRunner.shared.runGC()
        }

        return progress
    }
}

extension Progress {
    public var isYoutubeDownloadSuccessful: Bool {
        get {
            fileCompletedCount == fileTotalCount
        }
    }
}
