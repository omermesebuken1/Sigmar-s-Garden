//
//  PuzzleSolver.swift
//  Sigmar's Garden Map Generator
//
//  Checks if a puzzle is solvable using recursive backtracking
//

import Foundation

class PuzzleSolver {
    
    /// Check if a puzzle is solvable
    /// Returns true if a solution exists, false otherwise
    static func isSolvable(_ cells: [Cell]) -> Bool {
        var mutableCells = cells
        updateSelectability(&mutableCells)
        return solve(&mutableCells)
    }
    
    // MARK: - Private Solver
    
    private static func solve(_ cells: inout [Cell]) -> Bool {
        // Check if puzzle is complete (no atoms left)
        let remainingAtoms = cells.filter { !$0.contains.isEmpty && $0.contains != "ph" }
        if remainingAtoms.isEmpty {
            return true // Solved!
        }
        
        // Get all possible moves
        let moves = findAllMoves(cells)
        
        if moves.isEmpty {
            return false // No moves available, puzzle is stuck
        }
        
        // Try each move
        for move in moves {
            // Save state
            let savedCells = cells
            
            // Apply move
            applyMove(&cells, move: move)
            updateSelectability(&cells)
            
            // Recursively try to solve
            if solve(&cells) {
                return true
            }
            
            // Restore state (backtrack)
            cells = savedCells
        }
        
        return false // No solution found
    }
    
    // MARK: - Move Finding
    
    private static func findAllMoves(_ cells: [Cell]) -> [Move] {
        var moves: [Move] = []
        
        // Get all selectable cells with atoms
        let selectableCells = cells.filter {
            $0.selectable && !$0.contains.isEmpty && $0.contains != "ph"
        }
        
        // Check for gold (can be taken alone)
        for cell in selectableCells {
            if cell.contains == "gold" {
                moves.append(Move(cell1: cell.id, cell2: nil, type: .gold))
            }
        }
        
        // Check all pairs for matches
        for i in 0..<selectableCells.count {
            for j in (i+1)..<selectableCells.count {
                let cell1 = selectableCells[i]
                let cell2 = selectableCells[j]
                
                if canMatch(cell1.contains, cell2.contains) {
                    moves.append(Move(cell1: cell1.id, cell2: cell2.id, type: .pair))
                }
            }
        }
        
        return moves
    }
    
    private static func canMatch(_ atom1: String, _ atom2: String) -> Bool {
        if atom1 == "gold" || atom2 == "gold" {
            return false
        }
        return MatchingRules.canMatch(atom1, atom2)
    }
    
    // MARK: - Move Application
    
    private static func applyMove(_ cells: inout [Cell], move: Move) {
        if let index1 = cells.firstIndex(where: { $0.id == move.cell1 }) {
            cells[index1].contains = ""
        }
        
        if let cell2 = move.cell2,
           let index2 = cells.firstIndex(where: { $0.id == cell2 }) {
            cells[index2].contains = ""
        }
    }
    
    // MARK: - Selectability Update
    
    private static func updateSelectability(_ cells: inout [Cell]) {
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
            
            // Metal chain logic - only the first available metal in chain is selectable
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

// MARK: - Move Type

private struct Move {
    let cell1: Int
    let cell2: Int?
    let type: MoveType
    
    enum MoveType {
        case pair   // Two cells matched
        case gold   // Gold taken alone
    }
}

