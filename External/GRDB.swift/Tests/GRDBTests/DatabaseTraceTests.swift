import XCTest
import GRDB

class DatabaseTraceTests : GRDBTestCase {
    func testTraceStatementExpandedSQL() throws {
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            var lastExpandedSQL: String?
            db.trace(options: .statement) { event in
                switch event {
                case let .statement(statement):
                    lastExpandedSQL = statement.expandedSQL
                default:
                    XCTFail("Unexpected event")
                }
            }
            try db.execute(sql: "CREATE table t(a);")
            XCTAssertEqual(lastExpandedSQL, "CREATE table t(a)")
            
            try db.execute(sql: "INSERT INTO t (a) VALUES (?)", arguments: [1])
            XCTAssertEqual(lastExpandedSQL, "INSERT INTO t (a) VALUES (1)")
        }
    }
    
    func testTraceStatementSQL() throws {
        guard #available(OSX 10.12, tvOS 10.0, watchOS 3.0, *) else {
            throw XCTSkip("sqlite3_trace_v2 is not available")
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            var lastSQL: String?
            var lastDescription: String?
            db.trace(options: .statement) { event in
                lastDescription = event.description
                switch event {
                case let .statement(statement):
                    lastSQL = statement.sql
                default:
                    XCTFail("Unexpected event")
                }
            }
            try db.execute(sql: "CREATE table t(a);")
            XCTAssertEqual(lastSQL, "CREATE table t(a)")
            XCTAssertEqual(lastDescription, "CREATE table t(a)")
            
            try db.execute(sql: "INSERT INTO t (a) VALUES (?)", arguments: [1])
            XCTAssertEqual(lastSQL, "INSERT INTO t (a) VALUES (?)")
            XCTAssertEqual(lastDescription, "INSERT INTO t (a) VALUES (1)")
        }
    }
    
    func testTraceProfile() throws {
        guard #available(OSX 10.12, tvOS 10.0, watchOS 3.0, *) else {
            throw XCTSkip("sqlite3_trace_v2 is not available")
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            var lastSQL: String?
            var lastExpandedSQL: String?
            var lastDuration: TimeInterval?
            var lastDescription: String?
            db.trace(options: .profile) { event in
                lastDescription = event.description
                switch event {
                case let .profile(statement: statement, duration: duration):
                    lastSQL = statement.sql
                    lastExpandedSQL = statement.expandedSQL
                    lastDuration = duration
                default:
                    XCTFail("Unexpected event")
                }
            }
            try db.execute(sql: "CREATE table t(a);")
            XCTAssertEqual(lastSQL, "CREATE table t(a)")
            XCTAssertEqual(lastExpandedSQL, "CREATE table t(a)")
            XCTAssertTrue(lastDuration! >= 0)
            XCTAssert(lastDescription!.hasSuffix("s CREATE table t(a)"))
            
            try db.execute(sql: "INSERT INTO t (a) VALUES (?)", arguments: [1])
            XCTAssertEqual(lastSQL, "INSERT INTO t (a) VALUES (?)")
            XCTAssertEqual(lastExpandedSQL, "INSERT INTO t (a) VALUES (1)")
            XCTAssertTrue(lastDuration! >= 0)
            XCTAssert(lastDescription!.hasSuffix("s INSERT INTO t (a) VALUES (1)"))
            
            db.add(function: DatabaseFunction("wait", argumentCount: 1, pure: true, function: { dbValues in
                if let delay = TimeInterval.fromDatabaseValue(dbValues[0]) {
                    Thread.sleep(forTimeInterval: delay)
                }
                return nil
            }))
            
            try db.execute(sql: "SELECT wait(?)", arguments: [0.5])
            XCTAssertEqual(lastSQL, "SELECT wait(?)")
            XCTAssertEqual(lastExpandedSQL, "SELECT wait(0.5)")
            XCTAssertGreaterThan(lastDuration!, 0.4)
            XCTAssertLessThan(lastDuration!, 2) // Travis can be so slow
            XCTAssert(lastDescription!.hasSuffix("s SELECT wait(0.5)"))
        }
    }
    
    func testTraceMultiple() throws {
        guard #available(OSX 10.12, tvOS 10.0, watchOS 3.0, *) else {
            throw XCTSkip("sqlite3_trace_v2 is not available")
        }
        
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            var events: [String] = []
            db.trace(options: [.statement, .profile]) { event in
                events.append(event.description)
            }
            try db.execute(sql: "CREATE table t(a);")
            XCTAssertEqual(events.count, 2)
        }
    }
    
    func testTraceFromConfigurationWithDefaultOptions() throws {
        var events: [String] = []
        var configuration = Configuration()
        configuration.prepareDatabase { db in
            db.trace { event in
                events.append("SQL: \(event)")
            }
        }
        let dbQueue = try makeDatabaseQueue(configuration: configuration)
        try dbQueue.inDatabase { db in
            try db.execute(sql: """
                CREATE table t(a);
                INSERT INTO t (a) VALUES (?)
                """, arguments: [1])
            XCTAssertEqual(events.suffix(2), [
                "SQL: CREATE table t(a)",
                "SQL: INSERT INTO t (a) VALUES (1)"])
        }
    }
    
    func testStopTrace() throws {
        let dbQueue = try makeDatabaseQueue()
        try dbQueue.inDatabase { db in
            var events: [String] = []
            db.trace(options: .statement) { event in
                events.append(event.description)
            }
            try db.execute(sql: "CREATE table t(a);")
            XCTAssertEqual(events.last, "CREATE table t(a)")
            
            db.trace(options: [])
            
            try db.execute(sql: "INSERT INTO t (a) VALUES (?)", arguments: [1])
            XCTAssertEqual(events.last, "CREATE table t(a)")
        }
    }
}
