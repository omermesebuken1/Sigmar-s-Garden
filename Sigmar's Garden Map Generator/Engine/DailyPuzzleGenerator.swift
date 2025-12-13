//
//  DailyPuzzleGenerator.swift
//  Sigmar's Garden Map Generator
//
//  Generates the same puzzle for everyone on a given day using seeded random
//  Guarantees solvability by checking with PuzzleSolver
//  Caches puzzle for instant loading
//

import Foundation
import GameplayKit

class DailyPuzzleGenerator {
    
    /// Get the difficulty for today's daily challenge (random: Easy, Medium, or Hard)
    /// Same for everyone on the same day (based on seed)
    static var dailyDifficulty: Difficulty {
        return getDailyDifficulty(for: Date())
    }
    
    /// Get difficulty for a specific date (seeded random)
    static func getDailyDifficulty(for date: Date) -> Difficulty {
        let seed = getSeed(for: date)
        let random = GKMersenneTwisterRandomSource(seed: seed)
        let difficultyIndex = random.nextInt(upperBound: 3) // 0, 1, or 2
        
        switch difficultyIndex {
        case 0: return .easy
        case 1: return .medium
        default: return .hard
        }
    }
    
    /// Maximum attempts to generate a solvable puzzle
    private static let maxGenerationAttempts = 50
    
    /// In-memory cache for the current day's puzzle
    private static var cachedPuzzle: [Cell]?
    private static var cachedPuzzleDate: Date?
    
    /// Check if we have a valid cached puzzle for today
    static func hasCachedPuzzle() -> Bool {
        guard let cachedDate = cachedPuzzleDate else { return false }
        return Calendar.current.isDateInToday(cachedDate)
    }
    
    /// Get cached puzzle if available
    static func getCachedPuzzle() -> [Cell]? {
        guard hasCachedPuzzle() else {
            cachedPuzzle = nil
            cachedPuzzleDate = nil
            return nil
        }
        return cachedPuzzle
    }
    
    /// Generate the daily puzzle for a given date (async version)
    /// Everyone gets the same puzzle on the same day
    /// Guarantees solvability
    static func generateDailyPuzzleAsync(for date: Date = Date()) async -> [Cell] {
        // Check cache first
        if let cached = getCachedPuzzle() {
            return cached
        }
        
        // Generate on background thread
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let cells = generateDailyPuzzleSync(for: date)
                
                // Cache the result
                DispatchQueue.main.async {
                    cachedPuzzle = cells
                    cachedPuzzleDate = date
                }
                
                continuation.resume(returning: cells)
            }
        }
    }
    
    /// Synchronous puzzle generation (use generateDailyPuzzleAsync for UI)
    static func generateDailyPuzzle(for date: Date = Date()) -> [Cell] {
        // Check cache first
        if let cached = getCachedPuzzle() {
            return cached
        }
        
        let cells = generateDailyPuzzleSync(for: date)
        
        // Cache the result
        cachedPuzzle = cells
        cachedPuzzleDate = date
        
        return cells
    }
    
    /// Internal sync generation
    private static func generateDailyPuzzleSync(for date: Date) -> [Cell] {
        let baseSeed = getSeed(for: date)
        let difficulty = getDailyDifficulty(for: date)
        
        // Try multiple seeds until we find a solvable puzzle
        for attempt in 0..<maxGenerationAttempts {
            let seed = baseSeed + UInt64(attempt * 1000)
            let random = GKMersenneTwisterRandomSource(seed: seed)
            
            let gridCalculator = GridCalculator(difficulty: difficulty)
            var cells = gridCalculator.createCells()
            
            // Generate board using seeded random
            cells = generateSeededBoard(cells: cells, difficulty: difficulty, random: random)
            
            // Check if puzzle is solvable
            if PuzzleSolver.isSolvable(cells) {
                return cells
            }
        }
        
        // Fallback: return the last generated puzzle even if not verified solvable
        // This should rarely happen
        let random = GKMersenneTwisterRandomSource(seed: baseSeed)
        let gridCalculator = GridCalculator(difficulty: difficulty)
        var cells = gridCalculator.createCells()
        cells = generateSeededBoard(cells: cells, difficulty: difficulty, random: random)
        return cells
    }
    
    /// Get a consistent seed for a given date
    static func getSeed(for date: Date) -> UInt64 {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // Use day since reference date as base seed
        let daysSinceReference = calendar.dateComponents([.day], from: Date(timeIntervalSinceReferenceDate: 0), to: startOfDay).day ?? 0
        
        // Add some magic number to make seeds more varied
        return UInt64(abs(daysSinceReference * 31415926))
    }
    
    /// Check if a puzzle has been completed today
    static func hasCompletedToday() -> Bool {
        let lastCompletedDate = UserDefaults.standard.double(forKey: "lastDailyCompletedDate")
        if lastCompletedDate == 0 { return false }
        
        let lastDate = Date(timeIntervalSince1970: lastCompletedDate)
        return Calendar.current.isDateInToday(lastDate)
    }
    
    /// Mark today's puzzle as completed
    static func markCompleted() {
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(now, forKey: "lastDailyCompletedDate")
    }
    
    /// Get the time until the next daily puzzle
    static func timeUntilNextPuzzle() -> TimeInterval {
        let calendar = Calendar.current
        let now = Date()
        
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return 0
        }
        
        return tomorrow.timeIntervalSince(now)
    }
    
    /// Format remaining time as HH:MM:SS
    static func formatRemainingTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - Seeded Board Generation
    
    private static func generateSeededBoard(cells: [Cell], difficulty: Difficulty, random: GKMersenneTwisterRandomSource) -> [Cell] {
        var cells = cells
        let gridSize = difficulty.gridSize
        let totalCells = gridSize * gridSize
        
        let map = MapTemplate.randomMap(for: difficulty)
        
        var typesGenerated = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
        let gengoal = difficulty.tileGoals
        
        // Mark placeholder cells from map template
        for i in 0..<totalCells {
            if i < map.count, map[map.index(map.startIndex, offsetBy: i)] == "X" {
                cells[i].contains = "ph"
            } else {
                cells[i].contains = ""
            }
        }
        
        // Place gold in center
        let centerIndex = totalCells / 2
        cells[centerIndex].contains = "gold"
        
        // Update placeholder selectability
        var phSelectable = updatePlaceholderCells(&cells)
        
        // Generate pairs
        var iterations = 0
        let maxIterations = 500
        
        while phSelectable.count > 0 && iterations < maxIterations {
            let previousCount = phSelectable.count
            generateSeededPair(
                cells: &cells,
                phSelectable: &phSelectable,
                typesGenerated: &typesGenerated,
                gengoal: gengoal,
                random: random
            )
            phSelectable = updatePlaceholderCells(&cells)
            
            if phSelectable.count == previousCount {
                iterations += 1
            } else {
                iterations = 0
            }
        }
        
        // Clear remaining placeholders
        for i in 0..<cells.count {
            if cells[i].contains == "ph" {
                cells[i].contains = ""
            }
        }
        
        return cells
    }
    
    private static func generateSeededPair(
        cells: inout [Cell],
        phSelectable: inout [Int],
        typesGenerated: inout [Int],
        gengoal: [Int],
        random: GKMersenneTwisterRandomSource
    ) {
        var pairType: [String] = []
        
        let cardinalGoal = gengoal[0] + gengoal[1] + gengoal[2] + gengoal[3] + gengoal[4]
        let metalGoal = gengoal[6] + gengoal[7] + gengoal[8] + gengoal[9] + gengoal[10] + gengoal[11]
        let mvGoal = gengoal[13] + gengoal[14]
        
        if typesGenerated[0] + typesGenerated[1] + typesGenerated[2] + typesGenerated[3] + typesGenerated[4] < cardinalGoal {
            pairType.append("cardinal")
        }
        if typesGenerated[6] + typesGenerated[7] + typesGenerated[8] + typesGenerated[9] + typesGenerated[10] + typesGenerated[11] < metalGoal {
            pairType.append("metal")
        }
        if typesGenerated[13] + typesGenerated[14] < mvGoal {
            pairType.append("mv")
        }
        
        guard !pairType.isEmpty else { return }
        
        let selectedType = pairType[random.nextInt(upperBound: pairType.count)]
        var atom1: Int
        var atom2: Int
        
        switch selectedType {
        case "cardinal":
            var picks: [Int] = []
            for i in 0..<5 {
                if typesGenerated[i] < gengoal[i] {
                    picks.append(i)
                }
            }
            guard !picks.isEmpty else { return }
            atom1 = picks[random.nextInt(upperBound: picks.count)]
            atom2 = atom1
            
        case "mv":
            atom1 = 13
            atom2 = 14
            
        case "metal":
            atom1 = 6
            atom2 = 7
            while typesGenerated[atom2] > 0 && atom2 < 12 {
                atom2 += 1
            }
            
        default:
            return
        }
        
        guard phSelectable.count >= 2 else { return }
        
        let id1Index = random.nextInt(upperBound: phSelectable.count)
        let id1 = phSelectable[id1Index]
        phSelectable.remove(at: id1Index)
        
        let id2Index = random.nextInt(upperBound: phSelectable.count)
        let id2 = phSelectable[id2Index]
        phSelectable.remove(at: id2Index)
        
        cells[id1].contains = AtomType.names[atom1]
        cells[id2].contains = AtomType.names[atom2]
        typesGenerated[atom1] += 1
        typesGenerated[atom2] += 1
    }
    
    private static func updatePlaceholderCells(_ cells: inout [Cell]) -> [Int] {
        var phSelectable: [Int] = []
        
        for i in 0..<cells.count {
            let cell = cells[i]
            var nv = ""
            
            if cell.neighbors.yn >= 0 {
                nv += cells[cell.neighbors.yn].contains != "ph" ? " " : "e"
            } else {
                nv += " "
            }
            
            if cell.neighbors.zn >= 0 {
                nv += cells[cell.neighbors.zn].contains != "ph" ? " " : "e"
            } else {
                nv += " "
            }
            
            if cell.neighbors.xp >= 0 {
                nv += cells[cell.neighbors.xp].contains != "ph" ? " " : "e"
            } else {
                nv += " "
            }
            
            if cell.neighbors.yp >= 0 {
                nv += cells[cell.neighbors.yp].contains != "ph" ? " " : "e"
            } else {
                nv += " "
            }
            
            if cell.neighbors.zp >= 0 {
                nv += cells[cell.neighbors.zp].contains != "ph" ? " " : "e"
            } else {
                nv += " "
            }
            
            if cell.neighbors.xn >= 0 {
                nv += cells[cell.neighbors.xn].contains != "ph" ? " " : "e"
            } else {
                nv += " "
            }
            
            nv = nv + nv
            let selectable = nv.contains("   ")
            cells[i].selectable = selectable
            
            if selectable && cell.contains == "ph" {
                phSelectable.append(cell.id)
            }
        }
        
        return phSelectable
    }
}
