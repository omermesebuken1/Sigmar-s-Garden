//
//  Cell.swift
//  SigmarGarden
//
//  Created on iOS
//

import Foundation

struct Cell: Identifiable {
    let id: Int
    let x: Int
    let y: Int
    let z: Int
    let rendered: Bool
    var contains: String // AtomType rawValue veya "ph" (placeholder) veya "" (empty)
    var selectable: Bool
    let neighbors: Neighbors
    
    struct Neighbors {
        let yn: Int // y-1 (north)
        let zn: Int // x+1, y-1 (northeast)
        let xp: Int // x+1 (east)
        let yp: Int // y+1 (south)
        let zp: Int // x-1, y+1 (southwest)
        let xn: Int // x-1 (west)
    }
}

