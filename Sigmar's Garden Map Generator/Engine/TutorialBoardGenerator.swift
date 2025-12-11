//
//  TutorialBoardGenerator.swift
//  Sigmar's Garden Map Generator
//
//  Generates a special board for the tutorial
//

import Foundation

class TutorialBoardGenerator {
    static let gridSize = 7
    
    /// Create cells for the tutorial board (7x7)
    static func createCells() -> [Cell] {
        var cells: [Cell] = []
        
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let index = y * gridSize + x
                let z = x + y
                let minZ = Double(gridSize) * 0.5 - 1.5
                let maxZ = Double(gridSize) * 1.5 - 0.5
                let rendered = Double(z) > minZ && Double(z) < maxZ
                
                let neighbors = Cell.Neighbors(
                    yn: getCellByCoords(x: x, y: y - 1),
                    zn: getCellByCoords(x: x + 1, y: y - 1),
                    xp: getCellByCoords(x: x + 1, y: y),
                    yp: getCellByCoords(x: x, y: y + 1),
                    zp: getCellByCoords(x: x - 1, y: y + 1),
                    xn: getCellByCoords(x: x - 1, y: y)
                )
                
                let cell = Cell(
                    id: index,
                    x: x,
                    y: y,
                    z: z,
                    rendered: rendered,
                    contains: "",
                    selectable: true,
                    neighbors: neighbors
                )
                
                cells.append(cell)
            }
        }
        
        return cells
    }
    
    private static func getCellByCoords(x: Int, y: Int) -> Int {
        let minZ = Double(gridSize) * 0.5 - 1.5
        let maxZ = Double(gridSize) * 1.5 - 0.5
        
        if x >= 0 && Double(x + y) > minZ && y >= 0 && x < gridSize && Double(x + y) < maxZ && y < gridSize {
            return y * gridSize + x
        }
        return -1
    }
    
    /// Generate the tutorial board with specific tile placements
    /// Layout designed for teaching each rule step by step
    static func generateTutorialBoard() -> [Cell] {
        var cells = createCells()
        
        // Clear all cells first
        for i in 0..<cells.count {
            cells[i].contains = ""
        }
        
        // Place tiles strategically for tutorial
        // Center is at (3, 3) = index 24
        // 7x7 grid indices for rendered hexagons:
        //
        //        Row 0:     3,4,5,6  (indices 3,4,5,6)
        //        Row 1:    2,3,4,5,6 (indices 9,10,11,12,13)
        //        Row 2:   1,2,3,4,5,6 (indices 15,16,17,18,19,20)
        //        Row 3:  0,1,2,3,4,5,6 (indices 21,22,23,24,25,26,27)
        //        Row 4:   0,1,2,3,4,5 (indices 28,29,30,31,32,33)
        //        Row 5:    0,1,2,3,4 (indices 35,36,37,38,39)
        //        Row 6:     0,1,2,3  (indices 42,43,44,45)
        
        // Tutorial layout:
        // Step 3 (Cardinal): Two Fire elements
        cells[10].contains = "fire"   // Top area
        cells[12].contains = "fire"   // Top area
        
        // Step 4 (Salt): Salt + Water
        cells[16].contains = "salt"   // Left side
        cells[18].contains = "water"  // Right side
        
        // Step 5 (Mors/Vitae): Mors + Vitae
        cells[29].contains = "mors"   // Bottom left
        cells[33].contains = "vitae"  // Bottom right
        
        // Step 6 (Metals): Quicksilver + Lead
        cells[22].contains = "quicksilver"  // Left of center
        cells[26].contains = "lead"         // Right of center
        
        // Step 7 (Gold): Gold in center
        cells[24].contains = "gold"  // Center (3,3)
        
        return cells
    }
    
    /// Update cell selectability based on current state
    static func updateSelectability(_ cells: inout [Cell]) {
        for i in 0..<cells.count {
            var nv = ""
            
            if cells[i].neighbors.yn >= 0 {
                nv += cells[cells[i].neighbors.yn].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            if cells[i].neighbors.zn >= 0 {
                nv += cells[cells[i].neighbors.zn].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            if cells[i].neighbors.xp >= 0 {
                nv += cells[cells[i].neighbors.xp].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            if cells[i].neighbors.yp >= 0 {
                nv += cells[cells[i].neighbors.yp].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            if cells[i].neighbors.zp >= 0 {
                nv += cells[cells[i].neighbors.zp].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            if cells[i].neighbors.xn >= 0 {
                nv += cells[cells[i].neighbors.xn].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            nv = nv + nv
            cells[i].selectable = nv.contains("   ")
            
            // Metal chain logic
            if AtomType.metals.contains(cells[i].contains) {
                let metalIndex = AtomType.metals.firstIndex(of: cells[i].contains) ?? 0
                if metalIndex > 0 {
                    let previousMetal = AtomType.metals[metalIndex - 1]
                    let hasPreviousMetal = cells.contains { $0.contains == previousMetal }
                    if hasPreviousMetal {
                        cells[i].selectable = false
                    }
                }
            }
        }
    }
}

