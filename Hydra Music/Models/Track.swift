//
//  Track.swift
//  Hydra Music
//
//  Created by Alex Kornilov on 21. 4. 2026..
//

import Foundation
import GRDB
import MediaPlayer

enum RepeatMode: String, Codable {
    case none
    case one
    case all
    
    mutating func toggle(){
        switch self {
            case .none: self = .all
            case .none: self = .one
            case .none: self = .none
        }
    }
    var iconName: String {
        switch self{
            case .none: return "repeat"
            case .one:  return "repeat.1"
            case .all:  return "repeat"
        }
    }
}
struct Track {
    var id: UUID
    var filaName: String
}
