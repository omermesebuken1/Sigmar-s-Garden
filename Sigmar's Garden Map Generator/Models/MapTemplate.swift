//
//  MapTemplate.swift
//  SigmarGarden
//
//  Created on iOS
//

import Foundation

struct MapTemplate {
    // Original 11x11 maps (121 characters each)
    static let hardMaps = [
        "      XXX         XX X   XX  X  X  XXXXXX XX X  XXXXXX    XXXXX    XXXXXX  X XX XXXXXX  X  X  XX   X XX         XXX      ",
        "     XX  XX    XXX XXX    XX  XX      X X    XX  XX  XXXXXXXXXXXXXXX  XX  XX    X X      XX  XX    XXX XXX    XX  XX     ",
        "     XXXXXX    XXXXXXX   XX    XX  XX     XX XX      XXXX   X   XXXX      XX XX     XX  XX    XX   XXXXXXX    XXXXXX     ",
        "     X  X X     XXX X    X X XXX    XX X  XX  X XXXXX  XXX XXX XXX  XXXXX X  XX  X XX    XXX X X    X XXX     X X  X     ",
        "     XXXX      XXX   X   XXX   XX  XXX    XX XX XXXXXXX    XXX XXX    XX  XX X   X   X  XXXX   X   XXXXX      XXXXX      ",
        "     X    X    X XX  X   X XX XXX  X  X XXXX X    XXXXXXXX  X  XXXXXXXX    X XXXX X  X  XXX XX X   X  XX X    X    X     ",
        "     XXXXXX    XX   XX   XX    XX  XX  X  XX XX  XX  XXXX  XXX  XXX  XXXX  X X       X  X      X   XXXXXXX    XXXXXX     "
    ]
    
    /// Generate a hexagonal map for a given grid size
    static func generateHexMap(gridSize: Int) -> String {
        var result = ""
        let center = gridSize / 2
        let maxRadius = center
        
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let z = x + y
                let minZ = Double(gridSize) * 0.5 - 1.5
                let maxZ = Double(gridSize) * 1.5 - 0.5
                
                // Check if cell is within hex bounds
                let isInHex = Double(z) > minZ && Double(z) < maxZ
                
                if isInHex {
                    // Calculate distance from center for variation
                    let dx = x - center
                    let dy = y - center
                    let distFromCenter = abs(dx) + abs(dy) + abs(dx + dy)
                    
                    // Most cells are placeholders, with some random empty spots
                    if distFromCenter <= maxRadius * 2 {
                        // Random pattern - about 80% filled
                        if Int.random(in: 0..<10) < 8 {
                            result += "X"
                        } else {
                            result += " "
                        }
                    } else {
                        result += " "
                    }
                } else {
                    result += " "
                }
            }
        }
        
        return result
    }
    
    static func randomMap(for difficulty: Difficulty) -> String {
        switch difficulty {
        case .easy:
            return generateHexMap(gridSize: 7)
        case .medium:
            return generateHexMap(gridSize: 9)
        case .hard:
            // Use predefined maps for hard mode
            return hardMaps[Int.random(in: 0..<hardMaps.count)]
        }
    }
    
    /// Legacy function for backward compatibility
    static func randomMap() -> String {
        return randomMap(for: .hard)
    }
}
