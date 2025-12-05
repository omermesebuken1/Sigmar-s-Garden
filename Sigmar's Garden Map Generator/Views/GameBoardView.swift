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
    let onCellTapped: (Int) -> Void
    let availableSize: CGSize
    
    // Calculate hexagon size to fit screen
    private var hexSize: CGFloat {
        // Calculate based on available space
        let maxWidth = availableSize.width
        let maxHeight = availableSize.height
        
        // Estimate hexagon size based on grid
        let estimatedHexWidth = maxWidth / CGFloat(GridCalculator.gridSize + 1)
        let estimatedHexHeight = maxHeight / CGFloat(GridCalculator.gridSize + 1)
        
        // Use the smaller dimension to ensure it fits
        let size = min(estimatedHexWidth, estimatedHexHeight * 0.87) // 0.87 is hex aspect ratio
        
        // Clamp between reasonable values
        return max(30, min(size, 80))
    }
    
    private var hexWidth: CGFloat {
        return hexSize
    }
    
    private var hexHeight: CGFloat {
        return hexSize * 1.145 // Hexagon height ratio
    }
    
    // Center cell coordinates (5,5 for 11x11 grid)
    private var centerX: Int { GridCalculator.gridSize / 2 }
    private var centerY: Int { GridCalculator.gridSize / 2 }
    
    var body: some View {
        GeometryReader { geometry in
            let screenCenterX = geometry.size.width / 2
            let screenCenterY = geometry.size.height / 2
            
            ZStack {
                // Render all rendered cells (both empty and filled)
                ForEach(cells.filter { $0.rendered }) { cell in
                    cellView(for: cell)
                        .position(position(for: cell, screenCenter: CGPoint(x: screenCenterX, y: screenCenterY)))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color.clear)
    }
    
    private func position(for cell: Cell, screenCenter: CGPoint) -> CGPoint {
        // Calculate position relative to center cell (5,5)
        let xSpacing = hexWidth * 0.97
        let ySpacing = hexHeight * 0.75
        
        // Offset from center cell
        let deltaX = cell.x - centerX
        let deltaY = cell.y - centerY
        
        // Position relative to screen center
        // Each row shifts by half hexWidth for hex grid pattern
        let x = screenCenter.x + CGFloat(deltaX) * xSpacing + CGFloat(deltaY) * xSpacing * 0.5
        let y = screenCenter.y + CGFloat(deltaY) * ySpacing
        
        return CGPoint(x: x, y: y)
    }
    
    @ViewBuilder
    private func cellView(for cell: Cell) -> some View {
        if cell.contains != "ph" && !cell.contains.isEmpty {
            AtomView(
                atomType: cell.contains,
                isSelectable: cell.selectable,
                isSelected: selectedCells.contains(cell.id),
                hexWidth: hexWidth,
                hexHeight: hexHeight
            )
            .frame(width: hexWidth, height: hexHeight)
            .onTapGesture {
                if cell.selectable {
                    onCellTapped(cell.id)
                }
            }
        } else {
            // Empty hexagon with beige background and light stroke
            HexagonView()
                .fill(Color(red: 0.86, green: 0.84, blue: 0.80).opacity(0.4)) // Bej/açık kahverengi
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: hexWidth, height: hexHeight)
        }
    }
}

