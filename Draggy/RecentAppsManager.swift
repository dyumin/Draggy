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

private struct OpenRecord {
    let file: String // absolute file path string
    let time: Date
}

class RecentAppsManager {
    public static let shared = try! RecentAppsManager()

    private init() throws {

        let appSupportDirectory = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(Bundle.main.bundleIdentifier!)
        if (!FileManager.default.fileExists(atPath: appSupportDirectory.path)) {
            try! FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: false, attributes: nil)
        }
        let dbURL = appSupportDirectory.appendingPathComponent("records.sqlite3")

        db = try! DatabasePool(path: dbURL.path)

        var migrator = DatabaseMigrator.init()
        migrator.registerMigration("create") { (db) in
            try! db.create(table: "apps", ifNotExists: true) { (t) in
                t.column("bundlePath", .text).notNull().primaryKey()
            }

            try! db.create(table: "open_records", ifNotExists: true, body: { (t) in
                t.column("absolutePath", .text).notNull()
                t.column("isDirectory", .boolean).notNull()
                t.column("advancedFileExtension", .boolean).notNull()
                t.column("pathExtension", .text).notNull()
                t.column("time", .datetime).notNull()
                t.column("bundlePath", .datetime).notNull()
                t.foreignKey(["bundlePath"], references: "apps", columns: ["bundlePath"])
            })
        }
        try! migrator.migrate(db!)

        records = []
        recentAppsPerType = [:]
    }

    var db: DatabasePool?

    func applicationWillTerminate() {
        db = nil // close db connection
    }

    deinit { // TODO: not called

    }

    private var records: [OpenRecord]

    private var recentAppsPerType: [String: [Bundle]]

    func recentApps(for file: URL, _ type: RecentType) -> [Bundle] { // TODO: synchronisation?
        let pathExtension = file.pathExtension
        if (pathExtension.isEmpty) {
            return [] // todo: use advanced file type calculation
        }

        if let recentApps = recentAppsPerType[pathExtension] {
            return recentApps
        }

        var data = [Bundle]()
        try! db!.read({ (db) in
            let apps = try URL.fetchCursor(db, sql: "SELECT DISTINCT bundlePath FROM open_records WHERE pathExtension = ?", arguments: [pathExtension])
            while let url = try apps.next() {
                data.append(Bundle(url: url)!)
            }
        })

        data = data.reversed()

        recentAppsPerType[pathExtension] = data

        return data
    }

    func clearRecent(for file: URL, _ type: RecentType) {
        let pathExtension = file.pathExtension
        if !pathExtension.isEmpty {
            recentAppsPerType[pathExtension] = []
            try! db!.write { db in
                try db.execute(sql: "DELETE FROM open_records WHERE pathExtension = ?", arguments: [pathExtension])
            }
        }
    }

    func didOpen(_ file: URL, with app: Bundle) {

        guard let db = db else {
            return
        }

        let pathExtension = file.pathExtension
        if (!pathExtension.isEmpty) {
            if var recentApps = recentAppsPerType[pathExtension] { // TODO: sync?
                if (!recentApps.contains(app)) {
                    recentApps.insert(app, at: 0)
                    recentAppsPerType[pathExtension] = recentApps // wtf swift
                }
            } else {
                recentAppsPerType[pathExtension] = [app]
            }
        }

        var isDirectory = ObjCBool(false)
        if (!FileManager.default.fileExists(atPath: file.path, isDirectory: &isDirectory)) {
            print("!fileExists ", file)
            return
        }

        let literal: SQLLiteral = """
                                  INSERT INTO open_records (absolutePath, isDirectory, advancedFileExtension, pathExtension, time, bundlePath) VALUES (\(file.absoluteURL), \(isDirectory.boolValue), \(false), \(pathExtension), \(Date()), \(app.bundleURL))
                                  """

        do {
            try db.write { db in
                try db.execute(literal: literal)
            }
        } catch let error as GRDB.DatabaseError {
            if (error.extendedResultCode.rawValue == GRDB.DatabaseError.SQLITE_CONSTRAINT_FOREIGNKEY.rawValue) {
                try! db.write { db in
                    try db.execute(literal: """
                                            INSERT INTO apps (bundlePath) VALUES (\(app.bundleURL))
                                            """)
                    try db.execute(literal: literal)
                }
            } else {
                fatalError(error.description)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
}
