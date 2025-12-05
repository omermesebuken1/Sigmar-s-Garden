//
//  MapTemplate.swift
//  SigmarGarden
//
//  Created on iOS
//

import Foundation

struct MapTemplate {
    static let maps = [
        "      XXX         XX X   XX  X  X  XXXXXX XX X  XXXXXX    XXXXX    XXXXXX  X XX XXXXXX  X  X  XX   X XX         XXX      ",
        "     XX  XX    XXX XXX    XX  XX      X X    XX  XX  XXXXXXXXXXXXXXX  XX  XX    X X      XX  XX    XXX XXX    XX  XX     ",
        "     XXXXXX    XXXXXXX   XX    XX  XX     XX XX      XXXX   X   XXXX      XX XX     XX  XX    XX   XXXXXXX    XXXXXX     ",
        "     X  X X     XXX X    X X XXX    XX X  XX  X XXXXX  XXX XXX XXX  XXXXX X  XX  X XX    XXX X X    X XXX     X X  X     ",
        "     XXXX      XXX   X   XXX   XX  XXX    XX XX XXXXXXX    XXX XXX    XX  XX X   X   X  XXXX   X   XXXXX      XXXXX      ",
        "     X    X    X XX  X   X XX XXX  X  X XXXX X    XXXXXXXX  X  XXXXXXXX    X XXXX X  X  XXX XX X   X  XX X    X    X     ",
        "     XXXXXX    XX   XX   XX    XX  XX  X  XX XX  XX  XXXX  XXX  XXX  XXXX  X X       X  X      X   XXXXXXX    XXXXXX     "
    ]
    
    static func randomMap() -> String {
        return maps[Int.random(in: 0..<maps.count)]
    }
}

