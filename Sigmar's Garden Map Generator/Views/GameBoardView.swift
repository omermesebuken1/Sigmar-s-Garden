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
    let isGameActive: Bool  // NEW: determines if tiles should show selectability
    let onCellTapped: (Int) -> Void
    let availableSize: CGSize
    
    // Hexagon dimensions
    private var hexHeight: CGFloat {
        let size = availableSize.height / 12
        return max(28, min(size, 41))
    }
    
    private var hexWidth: CGFloat {
        return hexHeight * 1.15
    }
    
    // Center cell coordinates
    private var centerX: Int { GridCalculator.gridSize / 2 }
    private var centerY: Int { GridCalculator.gridSize / 2 }
    
    var body: some View {
        GeometryReader { geometry in
            let screenCenterX = geometry.size.width / 2
            let screenCenterY = geometry.size.height / 2
            
            ZStack {
                ForEach(cells.filter { $0.rendered }) { cell in
                    HexTileView(
                        atomType: cell.contains.isEmpty ? nil : cell.contains,
                        isSelectable: isGameActive ? cell.selectable : false,  // All locked if game not active
                        isSelected: selectedCells.contains(cell.id),
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
        let minX = max(0, 5 - y)
        let maxX = min(10, 15 - y)
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
