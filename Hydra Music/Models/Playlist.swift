//
//  Playlist.swift
//  Hydra Music
//
//  Created by Alex Kornilov on 21. 4. 2026..
//

import Foundation
import GRDB

struct Playlist {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var coverAtworkPath: String?

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        coverArtworkPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.coverArtworkPath = coverArtworkPath
    }
}

extension Playlist: Identifiable {}
extension Playlist: Codable {}

extension Playlist: FetchableRecord {
    init(row: Row) throws {
        id = row["id"]
        name = row["name"]
        createdAt = row["createdAt"]
        updatedAt = row["updatedAt"]
        coverArtworkPath = row["coverArtworkPath"]
    }
}

extension Playlist: PersistableRecord {
    static var databaseTableName: String {
        "playlists"
    }

    func encode(to container: inout PersistenceContainer) throws {
        container["id"] = id.uuidString
        container["name"] = name
        container["createdAt"] = createdAt
        container["updatedAt"] = updatedAt
        container["coverArtworkPath"] = coverArtworkPath
    }
}

/// Junction Table
struct PlaylistTrack {
    var playlistId: UUID
    var trackId: UUID
    var position: Int
}

extension PlaylistTrack: FetchableRecord {
    init(row: Row) throws {
        playlistId = row["playlistId"]
        trackId = row["trackId"]
        position = row["position"]
    }
}

extension PlaylistTrack: PersistableRecord {
    static var databaseTableName: String {
        "playlist_tracks"
    }

    func encode(to container: inout PersistenceContainer) throws {
        container["playlistId"] = playlistId.uuidString
        container["trackId"] = trackId.uuidString
        container["position"] = position
    }
}

extension Playlist {
    var formattedUpdatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}
