GRDB ❤️ Combine
===============

**On systems supporting the Combine framework, GRDB offers the ability to publish database values and events using Combine's publishers.**

- [Usage]
- [Demo Application]
- [Asynchronous Database Access]
- [Database Observation]

## Usage

To connect to the database, please refer to [Database Connections].

<details>
  <summary><strong>Asynchronously read from the database</strong></summary>
  
This publisher reads a single value and delivers it.

```swift
// DatabasePublishers.Read<[Player]>
let players = dbQueue.readPublisher { db in
    try Player.fetchAll(db)
}
```

</details>

<details>
  <summary><strong>Asynchronously write in the database</strong></summary>
  
This publisher updates the database and delivers a single value.

```swift
// DatabasePublishers.Write<Void>
let write = dbQueue.writePublisher { db in
    try Player(...).insert(db)
}

// DatabasePublishers.Write<Int>
let newPlayerCount = dbQueue.writePublisher { db -> Int in
    try Player(...).insert(db)
    return try Player.fetchCount(db)
}
```

</details>

<details>
  <summary><strong>Observe changes in database values</strong></summary>

This publisher delivers fresh values whenever the database changes:

```swift
// A publisher with output [Player] and failure Error
let publisher = ValueObservation
    .tracking { db in try Player.fetchAll(db) }
    .publisher(in: dbQueue)

// A publisher with output Int? and failure Error
let publisher = ValueObservation
    .tracking { db in try Int.fetchOne(db, sql: "SELECT MAX(score) FROM player") }
    .publisher(in: dbQueue)
```

</details>

<details>
  <summary><strong>Observe database transactions</strong></summary>

This publisher delivers database connections whenever a database transaction has impacted an observed region:

```swift
// A publisher with output Database and failure Error
let publisher = DatabaseRegionObservation
    .tracking(Player.all())
    .publisher(in: dbQueue)

let cancellable = publisher.sink(
    receiveCompletion: { completion in ... },
    receiveValue: { (db: Database) in
        print("Exclusive write access to the database after players have been impacted")
    })

// A publisher with output Database and failure Error
let publisher = DatabaseRegionObservation
    .tracking(SQLRequest<Int>(sql: "SELECT MAX(score) FROM player"))
    .publisher(in: dbQueue)

let cancellable = publisher.sink(
    receiveCompletion: { completion in ... },
    receiveValue: { (db: Database) in
        print("Exclusive write access to the database after maximum score has been impacted")
    })
```

</details>


# Asynchronous Database Access

GRDB provide publishers that perform asynchronous database accesses.

- [`readPublisher(receiveOn:value:)`]
- [`writePublisher(receiveOn:updates:)`]
- [`writePublisher(receiveOn:updates:thenRead:)`]


#### `DatabaseReader.readPublisher(receiveOn:value:)`

This methods returns a publisher that completes after database values have been asynchronously fetched.

```swift
// DatabasePublishers.Read<[Player]>
let players = dbQueue.readPublisher { db in
    try Player.fetchAll(db)
}
```

Any attempt at modifying the database completes subscriptions with an error.

When you use a [database queue] or a [database snapshot], the read has to wait for any eventual concurrent database access performed by this queue or snapshot to complete.

When you use a [database pool], reads are generally non-blocking, unless the maximum number of concurrent reads has been reached. In this case, a read has to wait for another read to complete. That maximum number can be [configured].

This publisher can be subscribed from any thread. A new database access starts on every subscription.

The fetched value is published on the main queue, unless you provide a specific scheduler to the `receiveOn` argument.


#### `DatabaseWriter.writePublisher(receiveOn:updates:)`

This method returns a publisher that completes after database updates have been successfully executed inside a database transaction.

```swift
// DatabasePublishers.Write<Void>
let write = dbQueue.writePublisher { db in
    try Player(...).insert(db)
}

// DatabasePublishers.Write<Int>
let newPlayerCount = dbQueue.writePublisher { db -> Int in
    try Player(...).insert(db)
    return try Player.fetchCount(db)
}
```

This publisher can be subscribed from any thread. A new database access starts on every subscription.

It completes on the main queue, unless you provide a specific [scheduler] to the `receiveOn` argument.

When you use a [database pool], and your app executes some database updates followed by some slow fetches, you may profit from optimized scheduling with [`writePublisher(receiveOn:updates:thenRead:)`]. See below.


#### `DatabaseWriter.writePublisher(receiveOn:updates:thenRead:)`

This method returns a publisher that completes after database updates have been successfully executed inside a database transaction, and values have been subsequently fetched:

```swift
// DatabasePublishers.Write<Int>
let newPlayerCount = dbQueue.writePublisher(
    updates: { db in try Player(...).insert(db) }
    thenRead: { db, _ in try Player.fetchCount(db) })
}
```

It publishes exactly the same values as [`writePublisher(receiveOn:updates:)`]:

```swift
// DatabasePublishers.Write<Int>
let newPlayerCount = dbQueue.writePublisher { db -> Int in
    try Player(...).insert(db)
    return try Player.fetchCount(db)
}
```

The difference is that the last fetches are performed in the `thenRead` function. This function accepts two arguments: a readonly database connection, and the result of the `updates` function. This allows you to pass information from a function to the other (it is ignored in the sample code above).

When you use a [database pool], this method applies a scheduling optimization: the `thenRead` function sees the database in the state left by the `updates` function, and yet does not block any concurrent writes. This can reduce database write contention. See [Advanced DatabasePool](../README.md#advanced-databasepool) for more information.

When you use a [database queue], the results are guaranteed to be identical, but no scheduling optimization is applied.

This publisher can be subscribed from any thread. A new database access starts on every subscription.

It completes on the main queue, unless you provide a specific [scheduler] to the `receiveOn` argument.


# Database Observation

Database Observation publishers are based on [ValueObservation] and [DatabaseRegionObservation]. Please refer to their documentation for more information. If your application needs change notifications that are not built as Combine publishers, check the general [Database Changes Observation] chapter.

- [`ValueObservation.publisher(in:scheduling:)`]
- [`DatabaseRegionObservation.publisher(in:)`]


#### `ValueObservation.publisher(in:scheduling:)`

[ValueObservation] tracks changes in database values. You can turn it into a Combine publisher:

```swift
let observation = ValueObservation.tracking { db in
    try Player.fetchAll(db)
}

// A publisher with output [Player] and failure Error
let publisher = observation.publisher(in: dbQueue)
```

This publisher has the same behavior as ValueObservation:

- It notifies an initial value before the eventual changes.
- It may coalesce subsequent changes into a single notification.
- It may notify consecutive identical values. You can filter out the undesired duplicates with the `removeDuplicates()` Combine operator, but we suggest you have a look at the [removeDuplicates()](../README.md#valueobservationremoveduplicates) GRDB operator also.
- It stops emitting any value after the database connection is closed. But it never completes.
- By default, it notifies the initial value, as well as eventual changes and errors, on the main thread, asynchronously.
    
    This can be configured with the `scheduling` argument. It does not accept a Combine scheduler, but a [ValueObservation scheduler](../README.md#valueobservation-scheduling).
    
    For example, the `.immediate` scheduler makes sure the initial value is notified immediately when the publisher is subscribed. It can help your application update the user interface without having to wait for any asynchronous notifications:
    
    ```swift
    // Immediate notification of the initial value
    let cancellable = observation
        .publisher(
            in: dbQueue,
            scheduling: .immediate) // <-
        .sink(
            receiveCompletion: { completion in ... },
            receiveValue: { (players: [Player]) in print("Fresh players: \(players)") })
    // <- here "fresh players" is already printed.
    ```
    
    Note that the `.immediate` scheduler requires that the publisher is subscribed from the main thread. It raises a fatal error otherwise.

See [ValueObservation Scheduling](../README.md#valueobservation-scheduling) for more information.

:warning: **ValueObservation and Data Consistency**

When you compose ValueObservation publishers together with the [combineLatest](https://developer.apple.com/documentation/combine/publisher/3333677-combinelatest) operator, you lose all guarantees of [data consistency](https://en.wikipedia.org/wiki/Consistency_(database_systems)).

Instead, compose requests together into **one single** ValueObservation, as below:

```swift
struct HallOfFame {
    var totalPlayerCount: Int
    var bestPlayers: [Player]
}

// DATA CONSISTENCY GUARANTEED
let hallOfFamePublisher = ValueObservation
    .tracking { db -> HallOfFame in
        let totalPlayerCount = try Player.fetchCount(db)
        
        let bestPlayers = try Player
            .order(Column("score").desc)
            .limit(10)
            .fetchAll(db)
        
        return HallOfFame(
            totalPlayerCount: totalPlayerCount,
            bestPlayers: bestPlayers)
    }
    .publisher(in: dbQueue)
```

See [ValueObservation] for more information.


#### `DatabaseRegionObservation.publisher(in:)`

[DatabaseRegionObservation] notifies all transactions that impact a tracked database region. You can turn it into a Combine publisher:

```swift
let request = Player.all()
let observation = DatabaseRegionObservation.tracking(request)

// A publisher with output Database and failure Error
let publisher = observation.publisher(in: dbQueue)
```

This publisher can be created and subscribed from any thread. It delivers database connections in a "protected dispatch queue", serialized with all database updates. It only completes when a database error happens.

```swift
let request = Player.all()
let cancellable = DatabaseRegionObservation
    .tracking(request)
    .publisher(in: dbQueue)
    .sink(
        receiveCompletion: { completion in ... },
        receiveValue: { (db: Database) in
            print("Players have changed.")
        })

try dbQueue.write { db in
    try Player(name: "Arthur").insert(db)
    try Player(name: "Barbara").insert(db)
} 
// Prints "Players have changed."

try dbQueue.write { db in
    try Player.deleteAll(db)
}
// Prints "Players have changed."
```

See [DatabaseRegionObservation] for more information.


[Database Connections]: ../README.md#database-connections
[Usage]: #usage
[Asynchronous Database Access]: #asynchronous-database-access
[Combine]: https://developer.apple.com/documentation/combine
[Database Changes Observation]: ../README.md#database-changes-observation
[Database Observation]: #database-observation
[DatabaseRegionObservation]: ../README.md#databaseregionobservation
[Demo Application]: DemoApps/GRDBCombineDemo/README.md
[SQLite]: http://sqlite.org
[ValueObservation]: ../README.md#valueobservation
[`DatabaseRegionObservation.publisher(in:)`]: #databaseregionobservationpublisherin
[`ValueObservation.publisher(in:scheduling:)`]: #valueobservationpublisherinscheduling
[`readPublisher(receiveOn:value:)`]: #databasereaderreadpublisherreceiveonvalue
[`writePublisher(receiveOn:updates:)`]: #databasewriterwritepublisherreceiveonupdates
[`writePublisher(receiveOn:updates:thenRead:)`]: #databasewriterwritepublisherreceiveonupdatesthenread
[configured]: ../README.md#databasepool-configuration
[database pool]: ../README.md#database-pools
[database queue]: ../README.md#database-queues
[database snapshot]: ../README.md#database-snapshots
[scheduler]: https://developer.apple.com/documentation/combine/scheduler
