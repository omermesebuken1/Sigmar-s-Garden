//
//  MapGenerator.swift
//  SigmarGarden
//
//  Created on iOS
//

import Foundation

class MapGenerator {
    private var cells: [Cell]
    private var typesGenerated: [Int]
    private var phSelectable: [Int]
    private let difficulty: Difficulty
    private let gridSize: Int
    
    private var gengoal: [Int] {
        return difficulty.tileGoals
    }
    
    init(cells: [Cell], difficulty: Difficulty = .hard) {
        self.cells = cells
        self.difficulty = difficulty
        self.gridSize = difficulty.gridSize
        self.typesGenerated = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
        self.phSelectable = []
    }
    
    func generateBoard() -> [Cell] {
        let map = MapTemplate.randomMap(for: difficulty)
        let totalCells = gridSize * gridSize
        
        typesGenerated = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
        
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
        
        updatePlaceholderCells()
        
        // Generate pairs until no more placeholders
        // Safety limit to prevent infinite loops
        var iterations = 0
        let maxIterations = 500
        
        while phSelectable.count > 0 && iterations < maxIterations {
            let previousCount = phSelectable.count
            generatePair()
            updatePlaceholderCells()
            
            // If no progress was made, break to avoid infinite loop
            if phSelectable.count == previousCount {
                iterations += 1
            } else {
                iterations = 0
            }
        }
        
        // Clear any remaining placeholders
        for i in 0..<cells.count {
            if cells[i].contains == "ph" {
                cells[i].contains = ""
            }
        }
        
        return cells
    }
    
    private func generatePair() {
        var pairType: [String] = []
        
        // Calculate total goals from difficulty
        // Include salt (index 4) with cardinal elements so they're generated as pairs
        let cardinalGoal = gengoal[0] + gengoal[1] + gengoal[2] + gengoal[3] + gengoal[4]
        let metalGoal = gengoal[6] + gengoal[7] + gengoal[8] + gengoal[9] + gengoal[10] + gengoal[11]
        let mvGoal = gengoal[13] + gengoal[14]
        
        // Determine available pair types
        // Cardinal now includes salt (indices 0-4)
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
        
        let selectedType = pairType[Int.random(in: 0..<pairType.count)]
        var atom1: Int
        var atom2: Int
        
        switch selectedType {
        case "cardinal":
            // Include salt (index 4) - all cardinal elements pair with themselves
            var picks: [Int] = []
            for i in 0..<5 {  // 0-4: water, fire, air, earth, salt
                if typesGenerated[i] < gengoal[i] {
                    picks.append(i)
                }
            }
            guard !picks.isEmpty else { return }
            atom1 = picks[Int.random(in: 0..<picks.count)]
            atom2 = atom1
            
        case "mv":
            atom1 = 13 // mors
            atom2 = 14 // vitae
            
        case "metal":
            atom1 = 6 // quicksilver
            atom2 = 7 // lead
            while typesGenerated[atom2] > 0 && atom2 < 12 {
                atom2 += 1
            }
            
        default:
            return
        }
        
        // Place atoms in random selectable placeholder cells
        guard phSelectable.count >= 2 else { return }
        
        let id1Index = Int.random(in: 0..<phSelectable.count)
        let id1 = phSelectable[id1Index]
        phSelectable.remove(at: id1Index)
        
        let id2Index = Int.random(in: 0..<phSelectable.count)
        let id2 = phSelectable[id2Index]
        phSelectable.remove(at: id2Index)
        
        cells[id1].contains = AtomType.names[atom1]
        cells[id2].contains = AtomType.names[atom2]
        typesGenerated[atom1] += 1
        typesGenerated[atom2] += 1
    }
    
    private func updatePlaceholderCells() {
        phSelectable = []
        
        for i in 0..<cells.count {
            let cell = cells[i]
            var nv = ""
            
            // Check neighbors
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
            
            // Duplicate to check wraparound
            nv = nv + nv
            
            // A cell is selectable if it has 3 contiguous empty spaces
            let selectable = nv.contains("   ")
            
            cells[i].selectable = selectable
            
            if selectable && cell.contains == "ph" {
                phSelectable.append(cell.id)
            }
        }
    }
}

