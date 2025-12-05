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
    private var genSettings: GenSettings
    private var phSelectable: [Int]
    
    struct GenSettings {
        var salted: [Int] = []
    }
    
    let gengoal = [8, 8, 8, 8, 4, 0, 5, 1, 1, 1, 1, 1, 1, 4, 4]
    
    init(cells: [Cell]) {
        self.cells = cells
        self.typesGenerated = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
        self.genSettings = GenSettings()
        self.phSelectable = []
    }
    
    func generateBoard() -> [Cell] {
        let map = MapTemplate.randomMap()
        
        typesGenerated = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0]
        genSettings = GenSettings()
        genSettings.salted = [Int.random(in: 0..<5), Int.random(in: 0..<5)]
        
        // Mark placeholder cells from map template
        for i in 0..<121 {
            if map[map.index(map.startIndex, offsetBy: i)] == "X" {
                cells[i].contains = "ph"
            } else {
                cells[i].contains = ""
            }
        }
        
        // Place gold in center
        let centerIndex = Int(GridCalculator.gridSize * GridCalculator.gridSize / 2)
        cells[centerIndex].contains = "gold"
        
        updatePlaceholderCells()
        
        // Generate pairs until no more placeholders
        while phSelectable.count > 0 {
            generatePair()
            updatePlaceholderCells()
        }
        
        return cells
    }
    
    private func generatePair() {
        var pairType: [String] = []
        
        // Determine available pair types
        if typesGenerated[0] + typesGenerated[1] + typesGenerated[2] + typesGenerated[3] < 32 {
            pairType.append("cardinal")
        }
        if typesGenerated[6] + typesGenerated[7] + typesGenerated[8] + typesGenerated[9] + typesGenerated[10] + typesGenerated[11] < 10 {
            pairType.append("metal")
        }
        if typesGenerated[13] + typesGenerated[14] < 8 {
            pairType.append("mv")
        }
        if typesGenerated[4] < 4 {
            pairType.append("salted")
        }
        
        guard !pairType.isEmpty else { return }
        
        let selectedType = pairType[Int.random(in: 0..<pairType.count)]
        var atom1: Int
        var atom2: Int
        
        switch selectedType {
        case "cardinal":
            var picks: [Int] = []
            for i in 0..<4 {
                if typesGenerated[i] < 8 {
                    picks.append(i)
                }
            }
            guard !picks.isEmpty else { return }
            atom1 = picks[Int.random(in: 0..<picks.count)]
            atom2 = atom1
            
        case "salted":
            atom1 = genSettings.salted[Int.random(in: 0..<genSettings.salted.count)]
            atom2 = 4 // salt
            
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
        
        // Update salted settings
        if selectedType == "salted" && typesGenerated[atom1] % 2 == 0 {
            if let index = genSettings.salted.firstIndex(of: atom1) {
                genSettings.salted.remove(at: index)
            }
        }
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

