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

// internet connection is required
class YoutubeTests: XCTestCase {

    override func setUpWithError() throws {
        _ = Youtube.shared
    }

    func testGetVideoID() throws {
        popularVideos.forEach { (video) in
            XCTAssertEqual(Youtube.shared.getID(video.url), video.id)
        }
    }
}
