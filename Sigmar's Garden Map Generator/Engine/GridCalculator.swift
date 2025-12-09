//
//  GridCalculator.swift
//  SigmarGarden
//
//  Created on iOS
//

import Foundation

class GridCalculator {
    let gridSize: Int
    
    private var maxZ: Double {
        return Double(gridSize) * 1.5 - 0.5
    }
    
    private var minZ: Double {
        return Double(gridSize) * 0.5 - 1.5
    }
    
    init(difficulty: Difficulty) {
        self.gridSize = difficulty.gridSize
    }
    
    /// Legacy initializer for backward compatibility
    init(gridSize: Int = 11) {
        self.gridSize = gridSize
    }
    
    func getCellByCoords(x: Int, y: Int) -> Int {
        if x >= 0 && Double(x + y) > minZ && y >= 0 && x < gridSize && Double(x + y) < maxZ && y < gridSize {
            return y * gridSize + x
        }
        return -1
    }
    
    func createCells() -> [Cell] {
        var cells: [Cell] = []
        
        for y in 0..<gridSize {
            for x in 0..<gridSize {
                let index = y * gridSize + x
                let z = x + y
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
}

