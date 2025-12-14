//
//  GameBoardView.swift
//  SigmarGarden
//
//  Created on iOS
//

import SwiftUI

struct GameBoardView: View {
    let cells: [Cell]
    let selectedCells: Set<Int>
    let isGameActive: Bool  // determines if tiles should show selectability
    let gridSize: Int
    let onCellTapped: (Int) -> Void
    let availableSize: CGSize
    
    // Hexagon dimensions - scale based on grid size
    private var hexHeight: CGFloat {
        // Larger tiles for smaller grids
        let baseSize = availableSize.height / CGFloat(gridSize)
        switch gridSize {
        case 7:
            return max(40, min(baseSize, 55))
        case 9:
            return max(32, min(baseSize, 47))
        default: // 11 or other
            return max(28, min(baseSize, 39))
        }
    }
    
    private var hexWidth: CGFloat {
        return hexHeight * 1.15
    }
    
    // Center cell coordinates
    private var centerX: Int { gridSize / 2 }
    private var centerY: Int { gridSize / 2 }
    
    var body: some View {
        GeometryReader { geometry in
            let screenCenterX = geometry.size.width / 2
            let screenCenterY = geometry.size.height / 2
            
            ZStack {
                ForEach(cells.filter { $0.rendered }) { cell in
                    HexTileView(
                        atomType: cell.contains.isEmpty ? nil : cell.contains,
                        isSelectable: isGameActive ? cell.selectable : false,
                        isSelected: selectedCells.contains(cell.id),
                        isGameActive: isGameActive,
                        hexWidth: hexWidth,
                        hexHeight: hexHeight
                    )
                    .position(position(for: cell, screenCenter: CGPoint(x: screenCenterX, y: screenCenterY)))
                    .onTapGesture {
                        if isGameActive && cell.selectable && !cell.contains.isEmpty && cell.contains != "ph" {
                            onCellTapped(cell.id)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color.clear)
    }
    
    // Calculate the center row for a given column (y value)
    private func columnCenterRow(for y: Int) -> Double {
        let halfGrid = gridSize / 2
        let minX = max(0, halfGrid - y)
        let maxX = min(gridSize - 1, gridSize + halfGrid - 1 - y)
        return Double(minX + maxX) / 2.0
    }
    
    private func position(for cell: Cell, screenCenter: CGPoint) -> CGPoint {
        let col = cell.y - centerY
        
        let colSpacing = hexWidth * 0.76
        let rowSpacing = hexHeight * 0.97
        
        let x = screenCenter.x + CGFloat(col) * colSpacing
        
        let columnCenter = columnCenterRow(for: cell.y)
        let rowOffset = Double(cell.x) - columnCenter
        let y = screenCenter.y + CGFloat(rowOffset) * rowSpacing
        
        return CGPoint(x: x, y: y)
    }
}
