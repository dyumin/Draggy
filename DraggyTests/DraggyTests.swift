//
//  DraggyTests.swift
//  DraggyTests
//
//  Created by El D on 27.02.2021.
//

import XCTest
@testable import Draggy

class DraggyTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        _ = RecentAppsManager.shared
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // extension && mimetype -> save bundle as recent for both extension && mimetype, display as recent for both extension && mimetype
    func test_extension_and_mimetype() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "foo", mimetype: "bar"))
        
        let file2 = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        let app2 = SimpleBundle("/System/Applications/Utilities/Bluetooth File Exchange.app")
        RecentAppsManager.shared.didOpen(file2, with: app2, FileInfo(extension: "foo", mimetype: "not_bar"))
        
        let file3 = URL(fileURLWithPath: "/System/Applications/Utilities/Boot Camp Assistant.app")
        let app3 = SimpleBundle("/System/Applications/Utilities/ColorSync Utility.app")
        RecentAppsManager.shared.didOpen(file3, with: app3, FileInfo(extension: "not_foo", mimetype: "bar"))
        
        let recentAppsFooBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: "bar"))
        XCTAssertEqual(recentAppsFooBar, [app3, app2, app1])
        
        let recentAppsBarFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "bar", mimetype: "foo"))
        XCTAssertEqual(recentAppsBarFoo, [])
        
        let recentEmptyEmpty = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: ""))
        XCTAssertEqual(recentEmptyEmpty, [])
    }
    
    // extension -> save bundle as recent for extension (mimetype will be null), display as recent for extension and mimetypes used to match this extension
    func test_extension1() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "foo", mimetype: ""))
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsFoo, [app1])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsBar, [])
        
        let recentAppsFooBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: "bar"))
        XCTAssertEqual(recentAppsFooBar, [app1])
        
        let recentAppsBarFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "bar", mimetype: "foo"))
        XCTAssertEqual(recentAppsBarFoo, [])
        
        let recentEmptyEmpty = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: ""))
        XCTAssertEqual(recentEmptyEmpty, [])
        
    }
    
    // extension -> save bundle as recent for extension (mimetype will be null), display as recent for extension and mimetypes used to match this extension
    func test_extension2() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "foo", mimetype: ""))
        
        let file2 = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        let app2 = SimpleBundle("/System/Applications/Utilities/Bluetooth File Exchange.app")
        RecentAppsManager.shared.didOpen(file2, with: app2, FileInfo(extension: "foo", mimetype: "bar"))
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsFoo, [app2, app1])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsBar, [app2, app1])
        
        let recentAppsFooBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: "bar"))
        XCTAssertEqual(recentAppsFooBar, [app2, app1])
        
        let recentAppsBarFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "bar", mimetype: "foo"))
        XCTAssertEqual(recentAppsBarFoo, [])
        
        let recentEmptyEmpty = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: ""))
        XCTAssertEqual(recentEmptyEmpty, [])
    }

    // mimetype -> save bundle as recent for mimetype (extension will be null), display as recent for mimetype and extensions used to match this mimetype
    func test_mimetype1() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "", mimetype: "bar"))
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsFoo, [app1])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsBar, [])
        
        let recentAppsFooBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: "bar"))
        XCTAssertEqual(recentAppsFooBar, [app1])
        
        let recentAppsBarFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "bar", mimetype: "foo"))
        XCTAssertEqual(recentAppsBarFoo, [])
        
        let recentEmptyEmpty = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: ""))
        XCTAssertEqual(recentEmptyEmpty, [])
    }
    
    // mimetype -> save bundle as recent for mimetype (extension will be null), display as recent for mimetype and extensions used to match this mimetype
    func test_mimetype2() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "", mimetype: "bar"))
        
        let file2 = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        let app2 = SimpleBundle("/System/Applications/Utilities/Bluetooth File Exchange.app")
        RecentAppsManager.shared.didOpen(file2, with: app2, FileInfo(extension: "foo", mimetype: "bar"))
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsFoo, [app2, app1])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsBar, [app2, app1])
        
        let recentAppsFooBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: "bar"))
        XCTAssertEqual(recentAppsFooBar, [app2, app1])
        
        let recentAppsBarFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "bar", mimetype: "foo"))
        XCTAssertEqual(recentAppsBarFoo, [])
        
        let recentEmptyEmpty = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: ""))
        XCTAssertEqual(recentEmptyEmpty, [])
    }
    
    // empty && empty -> save bundle as used to open this particular file (extension and mimetype will be null), dont display as recent at all (unless display recent apps per file setting is on (not implemented yet))
    func test_empty_and_empty() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "", mimetype: ""))
        
        let file2 = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        let app2 = SimpleBundle("/System/Applications/Utilities/Bluetooth File Exchange.app")
        RecentAppsManager.shared.didOpen(file2, with: app2, FileInfo(extension: "", mimetype: ""))
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsFoo, [])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsBar, [])
        
        let recentAppsFooBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: "bar"))
        XCTAssertEqual(recentAppsFooBar, [])
        
        let recentAppsBarFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "bar", mimetype: "foo"))
        XCTAssertEqual(recentAppsBarFoo, [])
        
        let recentEmptyEmpty = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: ""))
        XCTAssertEqual(recentEmptyEmpty, [])
    }
    
    func test_clearRecent_for_file1() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "foo", mimetype: "bar"))
        
        let file2 = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        let app2 = SimpleBundle("/System/Applications/Utilities/Bluetooth File Exchange.app")
        RecentAppsManager.shared.didOpen(file2, with: app2, FileInfo(extension: "foo", mimetype: "not_bar"))
        
        let file3 = URL(fileURLWithPath: "/System/Applications/Utilities/Boot Camp Assistant.app")
        let app3 = SimpleBundle("/System/Applications/Utilities/ColorSync Utility.app")
        RecentAppsManager.shared.didOpen(file3, with: app3, FileInfo(extension: "not_foo", mimetype: "bar"))
        
        RecentAppsManager.shared.clearRecent(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        
        let recentAppsFooBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: "bar"))
        XCTAssertEqual(recentAppsFooBar, [app3])
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsFoo, [])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsBar, [app3])
        
        let recentAppsBarFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "bar", mimetype: "foo"))
        XCTAssertEqual(recentAppsBarFoo, [])
        
        let recentEmptyEmpty = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: ""))
        XCTAssertEqual(recentEmptyEmpty, [])
    }
    
    func test_clearRecent_for_file2() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "foo", mimetype: "bar"))

        let file2 = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        let app2 = SimpleBundle("/System/Applications/Utilities/Bluetooth File Exchange.app")
        RecentAppsManager.shared.didOpen(file2, with: app2, FileInfo(extension: "foo", mimetype: "not_bar"))

        let file3 = URL(fileURLWithPath: "/System/Applications/Utilities/Boot Camp Assistant.app")
        let app3 = SimpleBundle("/System/Applications/Utilities/ColorSync Utility.app")
        RecentAppsManager.shared.didOpen(file3, with: app3, FileInfo(extension: "not_foo", mimetype: "bar"))

        RecentAppsManager.shared.clearRecent(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))

        let recentAppsFooBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: "bar"))
        XCTAssertEqual(recentAppsFooBar, [app2])
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsFoo, [app2])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsBar, [])
        
        let recentAppsBarFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "bar", mimetype: "foo"))
        XCTAssertEqual(recentAppsBarFoo, [])
        
        let recentEmptyEmpty = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: ""))
        XCTAssertEqual(recentEmptyEmpty, [])
    }
    
    func test_clearRecent_for_file3() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "foo", mimetype: "bar"))

        let file2 = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        let app2 = SimpleBundle("/System/Applications/Utilities/Bluetooth File Exchange.app")
        RecentAppsManager.shared.didOpen(file2, with: app2, FileInfo(extension: "foo", mimetype: "not_bar"))

        let file3 = URL(fileURLWithPath: "/System/Applications/Utilities/Boot Camp Assistant.app")
        let app3 = SimpleBundle("/System/Applications/Utilities/ColorSync Utility.app")
        RecentAppsManager.shared.didOpen(file3, with: app3, FileInfo(extension: "not_foo", mimetype: "bar"))

        RecentAppsManager.shared.clearRecent(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: "bar"))

        let recentAppsFooBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: "bar"))
        XCTAssertEqual(recentAppsFooBar, [])
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsFoo, [])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsBar, [])
        
        let recentAppsBarFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "bar", mimetype: "foo"))
        XCTAssertEqual(recentAppsBarFoo, [])
        
        let recentEmptyEmpty = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: ""))
        XCTAssertEqual(recentEmptyEmpty, [])
    }
    
    func test_clearRecent_app_for_file1() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "foo", mimetype: "bar"))

        let file2 = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        RecentAppsManager.shared.didOpen(file2, with: app1, FileInfo(extension: "foo", mimetype: "not_bar"))

        let file3 = URL(fileURLWithPath: "/System/Applications/Utilities/Boot Camp Assistant.app")
        RecentAppsManager.shared.didOpen(file3, with: app1, FileInfo(extension: "not_foo", mimetype: "bar"))
        
        let file4 = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        let app2 = SimpleBundle("/System/Applications/Utilities/Bluetooth File Exchange.app")
        RecentAppsManager.shared.didOpen(file4, with: app2, FileInfo(extension: "extra_foo", mimetype: "extra_bar"))
        
        let file5 = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        let app3 = SimpleBundle("/System/Applications/Utilities/ColorSync Utility.app")
        RecentAppsManager.shared.didOpen(file5, with: app3, FileInfo(extension: "randomgkbskhgcsgmx", mimetype: "not_bar"))

        RecentAppsManager.shared.clearRecent(app1, for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsFoo, [])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsBar, [app1])
        
        let recentAppsNotFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "not_foo", mimetype: ""))
        XCTAssertEqual(recentAppsNotFoo, [app1])
        
        let recentAppsNotBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "not_bar"))
        XCTAssertEqual(recentAppsNotBar, [app3])
        
        let recentAppsExtraFooExtraBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "extra_foo", mimetype: "extra_bar"))
        XCTAssertEqual(recentAppsExtraFooExtraBar, [app2])
    }
    
    func test_clearRecent_app_for_file2() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "foo", mimetype: "bar"))

        let file2 = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        RecentAppsManager.shared.didOpen(file2, with: app1, FileInfo(extension: "foo", mimetype: "not_bar"))

        let file3 = URL(fileURLWithPath: "/System/Applications/Utilities/Boot Camp Assistant.app")
        RecentAppsManager.shared.didOpen(file3, with: app1, FileInfo(extension: "not_foo", mimetype: "bar"))
        
        let file4 = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        let app2 = SimpleBundle("/System/Applications/Utilities/ColorSync Utility.app")
        RecentAppsManager.shared.didOpen(file4, with: app2, FileInfo(extension: "extra_foo", mimetype: "extra_bar"))

        RecentAppsManager.shared.clearRecent(app1, for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsFoo, [app1])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsBar, [])
        
        let recentAppsExtraFooExtraBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "extra_foo", mimetype: "extra_bar"))
        XCTAssertEqual(recentAppsExtraFooExtraBar, [app2])
    }
    
    func test_clearRecent_app_for_file3() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "foo", mimetype: "bar"))

        let file2 = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        RecentAppsManager.shared.didOpen(file2, with: app1, FileInfo(extension: "foo", mimetype: "not_bar"))

        let file3 = URL(fileURLWithPath: "/System/Applications/Utilities/Boot Camp Assistant.app")
        RecentAppsManager.shared.didOpen(file3, with: app1, FileInfo(extension: "not_foo", mimetype: "bar"))
        
        let file4 = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        let app2 = SimpleBundle("/System/Applications/Utilities/ColorSync Utility.app")
        RecentAppsManager.shared.didOpen(file4, with: app2, FileInfo(extension: "extra_foo", mimetype: "extra_bar"))

        RecentAppsManager.shared.clearRecent(app1, for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: "bar"))
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsFoo, [])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsBar, [])
        
        let recentAppsExtraFooExtraBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "extra_foo", mimetype: "extra_bar"))
        XCTAssertEqual(recentAppsExtraFooExtraBar, [app2])
    }
    
    func test_clearRecent_app_for_file4() throws {
        RecentAppsManager.shared.test_db_reset()
        
        let file1 = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        let app1 = SimpleBundle("/System/Applications/Utilities/AirPort Utility.app")
        RecentAppsManager.shared.didOpen(file1, with: app1, FileInfo(extension: "foo", mimetype: "bar"))

        let file2 = URL(fileURLWithPath: "/System/Applications/Utilities/Audio MIDI Setup.app")
        RecentAppsManager.shared.didOpen(file2, with: app1, FileInfo(extension: "foo", mimetype: "not_bar"))

        let file3 = URL(fileURLWithPath: "/System/Applications/Utilities/Boot Camp Assistant.app")
        RecentAppsManager.shared.didOpen(file3, with: app1, FileInfo(extension: "not_foo", mimetype: "bar"))
        
        let file4 = URL(fileURLWithPath: "/System/Applications/Utilities/Console.app")
        let app2 = SimpleBundle("/System/Applications/Utilities/ColorSync Utility.app")
        RecentAppsManager.shared.didOpen(file4, with: app2, FileInfo(extension: "extra_foo", mimetype: "extra_bar"))

        RecentAppsManager.shared.clearRecent(app1, for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: ""))
        
        let recentAppsFoo = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "foo", mimetype: ""))
        XCTAssertEqual(recentAppsFoo, [app1])
        
        let recentAppsBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "", mimetype: "bar"))
        XCTAssertEqual(recentAppsBar, [app1])
        
        let recentAppsExtraFooExtraBar = RecentAppsManager.shared.recentApps(for: /* unused */ URL(fileURLWithPath: ""), .PerType, FileInfo(extension: "extra_foo", mimetype: "extra_bar"))
        XCTAssertEqual(recentAppsExtraFooExtraBar, [app2])
    }
}
