//
//  DatabaseManager.swift
//  Hydra Music
//
//  Created by Alex Kornilov on 22. 4. 2026..
//

import Foundation
import GRDB

final class DatabaseManager {
    static let shared = DatabaseManager()
    private let dbQueue: DatabaseQueue

    private init() {
        do {
            let documentsURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dbURL = documentsURL.appendingPathComponent("AppDatabase.sqlite")
            var config = Configuration()
            config.journalMode = .wal

            dbQueue = try DatabaseQueue(path: dbURL, configuration: config)
            try setupMigranions()

        } catch {
            fatalError("DatabaseManager initialization error: \(error)")
        }
    }

    private func setupMigranions() throws {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") {
            db in
            try db.create(table: "tracks") { t in
                t.column("id", .text).primaryKey().notNull()
                t.column("fileName", .text).notNull()
                t.column("title", .text).notNull()
                t.column("artist", .text).notNull()
                t.column("duration", .double).notNull()
                t.column("artworkPath", .text)
                t.column("bookmarkData", .blob)
                t.column("dateAdded", .datetime).notNull().indexed()
            }
            try db.create(table: "playlists") { t in
                t.column("id", .text).primaryKey().notNull()
                t.column("name", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull().indexed()
                t.column("coverArtworkPath", .text)
            }
            try db.create(table: "playlist_tracks") { t in
                t.primaryKey(["playlistId", "trackId"])
                t.column("playlistId", .text).notNull()
                    .references("playlists", column: "id", onDelete: .cascade)

                t.column("trackId", .text).notNull()
                    .references("tracks", column: "id", onDelete: .cascade)

                t.column("position", .integer).notNull().indexed()
            }
            migrator.registerMigration("v2") {
                db in
                try db.create(virtualTable: "tracks_fts", using: FTS5()) {
                    t in
                    t.content = "tracks"
                    t.column("title")
                    t.column("artist")
                    t.column("fileName")
                }
                try db.execute(sql: """
                    CREATE TRIGGER tracks_ai AFTER INSERT ON tracks BEGIN
                        INSERT INTO tracks_fts(rowid, title, artist, fileName)
                        VALUES (new.rowid, new.title, new.artist, new.fileName);
                    END
                """)
                try db.execute(sql: """
                    CREATE TRIGGER tracks_ad AFTER DELETE ON tracks BEGIN
                        INSERT INTO tracks_fts(tracks_fts, rowid, title, artist, fileName)
                        VALUES ('delete', old.rowid, old.title, old.artist, old.fileName);
                    END
                """)
                try db.execute(sql: """
                    CREATE TRIGGER tracks_au AFTER UPDATE ON tracks BEGIN
                        INSERT INTO tracks_fts(tracks_fts, rowid, title, artist, fileName)
                        VALUES ('delete', old.rowid, old.title, old.artist, old.fileName);
                        INSERT INTO tracks_fts(rowid, title, artist, fileName)
                        VALUES (new.rowid, new.title, new.artist, new.fileName);
                    END
                """)
            }
            #if DEBUG
                try migrator.migrate(dbQueue, upTo: .max)
            #else
                try migrator.migrate(dbQueue)
            #endif
            @discardableResult
            func write<T>(_ updates: @escaping (Database) throws -> T) async throws -> T {
                try await withCheckedThrowingContinuation { continuation in
                    do {
                        let result = try dbQueue.write { db in
                            try updates(db)
                        }

                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            func read<T>(_ value: @escaping (Database) throws -> T) async throws -> T {
                try await withCheckedThrowingContinuation { continuation in
                    do {
                        // dbQueue.read — фоновое чтение без блокировки записи
                        let result = try dbQueue.read { db in
                            try value(db)
                        }
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
