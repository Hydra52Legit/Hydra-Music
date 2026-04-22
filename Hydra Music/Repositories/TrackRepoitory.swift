//
//  TrackRepoitory.swift
//  Hydra Music
//
//  Created by Alex Kornilov on 22. 4. 2026..
//


import Foundation
import GRDB

final class TrackRepository {
    private let db: DatabaseManager
    
    init(db: DatabaseManager = .shared){
        self.db = db
    }
    
}
