//
//  RecentAppsManager.swift
//  Draggy
//
//  Created by El D on 22.02.2021.
//

import Cocoa
import GRDB

public enum RecentType {
    case PerFile
    case PerType
}

/**
 General rules:
    extension && mimetype -> save bundle as recent for both extension && mimetype, display as recent for both extension && mimetype
    extension             -> save bundle as recent for extension (mimetype will be null), display as recent for extension and mimetypes used to match this extension
    mimetype              -> save bundle as recent for mimetype (extension will be null), display as recent for mimetype and extensions used to match this mimetype
    empty && empty        -> save bundle as used to open this particular file (extension and mimetype will be null), dont display as recent at all (unless display recent apps per file setting is on (not implemented yet))
 */
struct FileInfo {
    let `extension`: String
    let mimetype: String

    var isEmpty: Bool {
        get {
            return mimetype.isEmpty && `extension`.isEmpty
        }
    }
}

class RecentAppsManager {
    public static let shared = try! RecentAppsManager()

    private init() throws {

        let appSupportDirectory = { () -> URL in
            if NSClassFromString("XCTest") != nil { // not reliable, but will do
                return FileManager.default.temporaryDirectory.appendingPathComponent(Bundle.main.bundleIdentifier!)
            }
            return try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(Bundle.main.bundleIdentifier!)
        }()
        if (!FileManager.default.fileExists(atPath: appSupportDirectory.path)) {
            try! FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: false, attributes: nil)
        }

        let dbURL = appSupportDirectory.appendingPathComponent("records.sqlite3")
        
        var config = Configuration()
        config.prepareDatabase { db in
            db.trace(options: .profile) { event in
                // Prints all SQL statements with their duration
//                print(event)

                // Access to detailed profiling information
                if case let .profile(statement, duration) = event, duration > 0.2 {
                    print("Slow query (\(duration)): \(statement.sql)")
                    // todo: compress db
                }
            }
        }

        db = try! DatabasePool(path: dbURL.path, configuration: config)

        var migrator = DatabaseMigrator.init()
        migrator.registerMigration("create") { (db) in
            try! db.create(table: "open_records", ifNotExists: true, body: { (t) in
                t.column("absolutePath", .text).notNull().check(sql: "absolutePath <> ''")
                t.column("isDirectory", .boolean).notNull()
                t.column("extension", .text).check(sql: "extension <> ''")
                t.column("mimetype", .text).check(sql: "mimetype <> ''")
                t.column("time", .datetime).notNull()
                t.column("bundlePath", .text).notNull().check(sql: "bundlePath <> ''")
            })
        }
        try! migrator.migrate(db!)
    }

    internal func test_db_reset() { // todo: any better way?
        try! db!.write { db in
            try db.execute(sql: "DELETE FROM open_records")
        }
    }

    private var db: DatabasePool?

    func applicationWillTerminate() {
        db = nil // close db connection
    }

    deinit { // TODO: not called

    }

    // acceptable race conditions with DispatchQoS.QoSClass.utility in func didOpen(_ file: URL, with app: Bundle, _ testFileInfo: FileInfo? = nil)
    // worst case scenario - recent app will not be shown to user once
    func recentApps(for file: URL, _ type: RecentType, /* tests only*/ _ testFileInfo: FileInfo? = nil) -> [SimpleBundle] { // TODO: synchronisation?

        let fileInfo = testFileInfo == nil ? FileInfo(extension: file.pathExtension, mimetype: FileDescription.getForFile(file) ?? "") : testFileInfo!

        guard !fileInfo.isEmpty else {
            return []
        }

        var extensionsForMimetypeContecanated: String = "''" // invalid value for the case if extensionsForMimetype is empty
        var extensionsForMimetype = Set<String>()
        if (!fileInfo.extension.isEmpty) {
            extensionsForMimetype.insert(fileInfo.extension)
        }

        var mimetypesForExtensionContecanated: String = "''" // invalid value for the case if mimetypesForExtension is empty
        var mimetypesForExtension = Set<String>()
        if (!fileInfo.mimetype.isEmpty) {
            mimetypesForExtension.insert(fileInfo.mimetype)
        }


        var data = [SimpleBundle]()
        try! db!.read({ (db) in
            do {
                if (!fileInfo.mimetype.isEmpty) {
                    let apps = try String.fetchCursor(db, sql: "SELECT DISTINCT extension FROM open_records WHERE mimetype = ? AND extension IS NOT NULL", arguments: [fileInfo.mimetype])
                    while let extensionForMimetype = try apps.next() {
                        extensionsForMimetype.insert(extensionForMimetype)
                    }
                }
                extensionsForMimetype.forEach { (str) in
                    extensionsForMimetypeContecanated.append(", '\(str)'")
                }
            }

            do {
                if (!fileInfo.extension.isEmpty) {
                    let apps = try String.fetchCursor(db, sql: "SELECT DISTINCT mimetype FROM open_records WHERE extension = ? AND mimetype IS NOT NULL", arguments: [fileInfo.extension])
                    while let extensionForMimetype = try apps.next() {
                        mimetypesForExtension.insert(extensionForMimetype)
                    }
                }
                mimetypesForExtension.forEach { (str) in
                    mimetypesForExtensionContecanated.append(", '\(str)'")
                }
            }

            do {
                // https://stackoverflow.com/questions/5391564/how-to-use-distinct-and-order-by-in-same-select-statement
                data = try String.fetchAll(db, sql: "SELECT bundlePath, MAX(time) FROM open_records WHERE (extension IN (\(extensionsForMimetypeContecanated)) OR mimetype IN (\(mimetypesForExtensionContecanated))) GROUP BY bundlePath ORDER BY MAX(time) DESC, bundlePath").map {
                    SimpleBundle($0)
                }
            }
        })

        return data
    }

    func clearRecent(for file: URL, _ type: RecentType, /* tests only*/ _ testFileInfo: FileInfo? = nil) {
        let fileInfo = testFileInfo == nil ? FileInfo(extension: file.pathExtension, mimetype: FileDescription.getForFile(file) ?? "") : testFileInfo!
        
        if !fileInfo.isEmpty {
            try! db!.write { db in
                try db.execute(sql: "DELETE FROM open_records WHERE extension = ? OR mimetype = ?", arguments: [fileInfo.extension, fileInfo.mimetype])
            }
        }
    }

    func clearRecent(_ app: SimpleBundle, for file: URL, _ type: RecentType, /* tests only*/ _ testFileInfo: FileInfo? = nil) {
        let fileInfo = testFileInfo == nil ? FileInfo(extension: file.pathExtension, mimetype: FileDescription.getForFile(file) ?? "") : testFileInfo!
        if !fileInfo.isEmpty {
            try! db!.write { db in
                try db.execute(sql: "DELETE FROM open_records WHERE (extension = ? OR mimetype = ?) AND bundlePath = ?", arguments: [fileInfo.extension, fileInfo.mimetype, app.bundleURL.path])
            }
        }
    }

    func didOpen(_ file: URL, with app: SimpleBundle, /* tests only*/ _ testFileInfo: FileInfo? = nil) {

        guard let db = db else {
            return
        }

        let block = {
            var isDirectory = ObjCBool(false)
            if (!FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory)) {
                print("!fileExists ", file)
                return
            }

            let fileInfo = testFileInfo == nil ? FileInfo(extension: file.pathExtension, mimetype: FileDescription.getForFile(file) ?? "") : {
                Thread.sleep(forTimeInterval: 0.001) // seems to be the delta for time precision in sqlite, otherwise files will seem as simultaneously opened; needed for tests
                return testFileInfo!
            }()

            // Dont serialise app.bundleURL URL directly
            // URL threats folders and files differently, folders get trailing slash in the representation, nonexistent folders treated as nonexistent files and dont get a trailing slash.
            // Existence check performed each time URL instance is created it seems
            // This may lead to inconsistent behaviour if app bundle is removed
            let literal: SQLLiteral = """
                                      INSERT INTO open_records (absolutePath, isDirectory, extension, mimetype, time, bundlePath) VALUES (\(file.absoluteURL), \(isDirectory.boolValue), \(fileInfo.extension.isEmpty ? nil : fileInfo.extension), \(fileInfo.mimetype.isEmpty ? nil : fileInfo.mimetype), \(Date()), \(app.bundleURL.path))
                                      """

            try! db.write { db in
                try! db.execute(literal: literal)
            }
        }

        if Thread.isMainThread && testFileInfo == nil { // run tests syncroniously
            DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async(execute: block) // may block userInteractive queue (func recentApps(for file: URL, _ type: RecentType, _ testFileInfo: FileInfo? = nil) -> [Bundle]) later if user drags again
        } else {
            block()
        }
    }
}
