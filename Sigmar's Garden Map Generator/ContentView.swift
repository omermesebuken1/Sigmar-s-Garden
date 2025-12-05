//
//  ContentView.swift
//  Sigmar's Garden Map Generator
//
//  Created by Ömer Faruk Meşebüken on 5.12.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var cells: [Cell] = []
    @State private var selectedCells: Set<Int> = []
    @State private var active = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - dark theme
                Color(red: 0.08, green: 0.08, blue: 0.1)
                    .ignoresSafeArea()
                
                // Game Board - centered with slight upward offset for better UX
                if !cells.isEmpty {
                    GameBoardView(
                        cells: cells,
                        selectedCells: selectedCells,
                        onCellTapped: handleCellTap,
                        availableSize: CGSize(
                            width: geometry.size.width,
                            height: geometry.size.height - 120
                        )
                    )
                    .offset(y: -120) // Shift up for better visual balance
                } else {
                    Text("Tap GENERATE to start")
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.55))
                        .offset(y: -50)
                }
                
                // NEW GAME Button at bottom
                VStack {
                    Spacer()
                    Button(action: {
                        generateNewGame()
                    }) {
                        Text("GENERATE")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(red: 0.2, green: 0.4, blue: 0.7))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .offset(y: -30) // Button yukarı kaydırma
            }
        }
        .onAppear {
            generateNewGame()
        }
    }
    
    private func generateNewGame() {
        var newCells = GridCalculator.createCells()
        let generator = MapGenerator(cells: newCells)
        newCells = generator.generateBoard()
        
        cells = newCells
        selectedCells = []
        active = true
    }
    
    private func handleCellTap(_ cellId: Int) {
        guard let cellIndex = cells.firstIndex(where: { $0.id == cellId }),
              cells[cellIndex].selectable else { return }
        
        if selectedCells.contains(cellId) {
            selectedCells.remove(cellId)
        } else {
            selectedCells.insert(cellId)
        }
        
        // Check if selection is valid move
        if selectedCells.count == 2 {
            let selectedAtoms = selectedCells.compactMap { id -> String? in
                guard let index = cells.firstIndex(where: { $0.id == id }) else { return nil }
                return cells[index].contains
            }
            
            if canMatch(selectedAtoms[0], selectedAtoms[1]) {
                // Remove matched cells
                var updatedCells = cells
                for id in selectedCells {
                    if let index = updatedCells.firstIndex(where: { $0.id == id }) {
                        updatedCells[index].contains = ""
                    }
                }
                cells = updatedCells
                selectedCells.removeAll()
                updateCellSelectability()
            } else if selectedAtoms.count > 1 && !selectedAtoms.contains("quintessence") {
                // Clear invalid selection
                selectedCells.removeAll()
            }
        } else if selectedCells.count == 1 {
            let selectedAtom = cells.first(where: { $0.id == Array(selectedCells)[0] })?.contains ?? ""
            if selectedAtom == "gold" {
                // Remove gold
                if let id = selectedCells.first,
                   let index = cells.firstIndex(where: { $0.id == id }) {
                    var updatedCells = cells
                    updatedCells[index].contains = ""
                    cells = updatedCells
                    selectedCells.removeAll()
                    updateCellSelectability()
                }
            }
        }
        
        // Clear selection if it cannot lead to a valid move
        if selectedCells.count > 1 {
            let selectedAtoms = selectedCells.compactMap { id -> String? in
                guard let index = cells.firstIndex(where: { $0.id == id }) else { return nil }
                return cells[index].contains
            }
            if !selectedAtoms.contains("quintessence") && selectedCells.count >= 2 {
                // Keep only the last selected if invalid
                if selectedCells.count > 2 {
                    let lastSelected = Array(selectedCells).last!
                    selectedCells = [lastSelected]
                }
            }
        }
    }
    
    private func canMatch(_ atom1: String, _ atom2: String) -> Bool {
        // Gold can be removed alone
        if atom1 == "gold" || atom2 == "gold" {
            return false // Handled separately
        }
        
        return MatchingRules.canMatch(atom1, atom2)
    }
    
    private func updateCellSelectability() {
        var updatedCells = cells
        for i in 0..<updatedCells.count {
            var nv = ""
            
            // Check neighbors
            if updatedCells[i].neighbors.yn >= 0 {
                nv += updatedCells[updatedCells[i].neighbors.yn].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            if updatedCells[i].neighbors.zn >= 0 {
                nv += updatedCells[updatedCells[i].neighbors.zn].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            if updatedCells[i].neighbors.xp >= 0 {
                nv += updatedCells[updatedCells[i].neighbors.xp].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            if updatedCells[i].neighbors.yp >= 0 {
                nv += updatedCells[updatedCells[i].neighbors.yp].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            if updatedCells[i].neighbors.zp >= 0 {
                nv += updatedCells[updatedCells[i].neighbors.zp].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            if updatedCells[i].neighbors.xn >= 0 {
                nv += updatedCells[updatedCells[i].neighbors.xn].contains.isEmpty ? " " : "e"
            } else {
                nv += " "
            }
            
            nv = nv + nv
            updatedCells[i].selectable = nv.contains("   ")
            
            // Metals can only be selected if previous metal is removed
            if AtomType.metals.contains(updatedCells[i].contains) {
                let metalIndex = AtomType.metals.firstIndex(of: updatedCells[i].contains) ?? 0
                if metalIndex > 0 {
                    let previousMetal = AtomType.metals[metalIndex - 1]
                    let hasPreviousMetal = updatedCells.contains { $0.contains == previousMetal }
                    if hasPreviousMetal {
                        updatedCells[i].selectable = false
                    }
                }
            }
        }
        cells = updatedCells
    }
}

#Preview {
    ContentView()
}
