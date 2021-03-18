//
//  Youtube.swift
//  DraggyTests
//
//  Created by El D on 17.03.2021.
//

import XCTest
@testable import Draggy

struct Video: Hashable {
    let id: String
    let url: URL
}

fileprivate let popularVideos: Set<Video> = [
    Video(id: "dQw4w9WgXcQ", url: URL(string: "https://www.youtube.com/watch?v=dQw4w9WgXcQ")!)
    , Video(id: "y6120QOlsfU", url: URL(string: "https://www.youtube.com/watch?v=y6120QOlsfU")!)
]

fileprivate let shortVideos: Set<Video> = [
    Video(id: "BaW_jenozKc", url: URL(string: "https://www.youtube.com/watch?v=BaW_jenozKc")!) // 1.7M Aug 27  2016 BaW_jenozKc.mp4
    , Video(id: "W9nZ6u15yis", url: URL(string: "https://www.youtube.com/watch?v=W9nZ6u15yis")!) // 131K May 20  2020 W9nZ6u15yis.mp4
]

// internet connection is required
class YoutubeTests: XCTestCase {

    override func setUpWithError() throws {
        _ = Youtube.shared
    }
    
    override func tearDownWithError() throws {
        cleanup()
    }
    
    var cleanupList = Set<URL>()
    
    func cleanup() {
        for item in cleanupList {
            try! FileManager.default.removeItem(at: item)
        }
    }

    func testGetVideoID() throws {
        popularVideos.forEach { (video) in
            XCTAssertEqual(Youtube.shared.getID(video.url), video.id)
        }
    }

    func testDownload() throws {
        var observations = [NSKeyValueObservation]()
        var expectations = [XCTestExpectation]()

        shortVideos.forEach { (video) in
            // Create an expectation for a background download task.
            let expectation = XCTestExpectation(description: "Download \(video)")
            expectations.append(expectation)

            let progress = Youtube.shared.download(video.url)
            observations.append(progress.observe(\.isFinished, options: [.initial, .new]) { [weak self] (progress, change) in
                if change.newValue == true {
                    XCTAssertTrue(progress.isYoutubeDownloadSuccessful)
                    XCTAssertTrue(FileManager.default.fileExists(atPath: progress.fileURL!.path))
                    self?.cleanupList.insert(progress.fileURL!)
                    expectation.fulfill()
                }
            })
        }

        // check same files
        shortVideos.forEach { (video) in
            // Create an expectation for a background download task.
            let expectation = XCTestExpectation(description: "Download again \(video)")
            expectations.append(expectation)

            let progress = Youtube.shared.download(video.url)
            observations.append(progress.observe(\.isFinished, options: [.initial, .new]) { [weak self] (progress, change) in
                if change.newValue == true {
                    XCTAssertTrue(progress.isYoutubeDownloadSuccessful)
                    XCTAssertTrue(FileManager.default.fileExists(atPath: progress.fileURL!.path))
                    self?.cleanupList.insert(progress.fileURL!)
                    expectation.fulfill()
                }
            })
        }

        wait(for: expectations, timeout: 120)
    }
}
