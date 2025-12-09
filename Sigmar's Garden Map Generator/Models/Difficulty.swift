//
//  Difficulty.swift
//  Sigmar's Garden Map Generator
//
//  Created for difficulty levels support
//

import Foundation

enum Difficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    
    var id: String { rawValue }
    
    var gridSize: Int {
        switch self {
        case .easy: return 7
        case .medium: return 9
        case .hard: return 11
        }
    }
    
    var displayName: String {
        switch self {
        case .easy: return "Kolay"
        case .medium: return "Orta"
        case .hard: return "Zor"
        }
    }
    
    /// Tile generation goals for each atom type
    /// Order: water, fire, air, earth, salt, quintessence, quicksilver, lead, tin, iron, copper, silver, gold, mors, vitae
    var tileGoals: [Int] {
        switch self {
        case .easy:
            // 7x7 grid - smaller counts but ALL metals included
            // Elements: 2 each, Salt: 2, QS: 5, All metals: 1 each, MV: 2 each
            return [2, 2, 2, 2, 2, 0, 5, 1, 1, 1, 1, 1, 1, 2, 2]
        case .medium:
            // 9x9 grid - medium counts with ALL metals
            // Elements: 4 each, Salt: 2, QS: 5, All metals: 1 each, MV: 2 each
            return [4, 4, 4, 4, 2, 0, 5, 1, 1, 1, 1, 1, 1, 2, 2]
        case .hard:
            // 11x11 grid - original counts
            // Elements: 8 each, Salt: 4, QS: 5, All metals: 1 each, MV: 4 each
            return [8, 8, 8, 8, 4, 0, 5, 1, 1, 1, 1, 1, 1, 4, 4]
        }
    }
    
    /// Leaderboard ID for best time
    var bestTimeLeaderboardID: String {
        return "garden.\(rawValue).besttime"
    }
    
    /// Leaderboard ID for solve count
    var solveCountLeaderboardID: String {
        return "garden.\(rawValue).solvecount"
    }
    
    /// AppStorage key for best time
    var bestTimeStorageKey: String {
        return "bestTime_\(rawValue)"
    }
    
    /// AppStorage key for solve count
    var solveCountStorageKey: String {
        return "solveCount_\(rawValue)"
    }
}

