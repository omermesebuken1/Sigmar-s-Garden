//
//  ContentView.swift
//  Sigmar's Garden Map Generator
//
//  Created by Ömer Faruk Meşebüken on 5.12.2025.
//

import SwiftUI
import Combine

struct ContentView: View {
    @State private var cells: [Cell] = []
    @State private var selectedCells: Set<Int> = []
    @State private var isPlaying = false
    @State private var isCompleted = false
    @State private var isNewHighScore = false
    @State private var showRestartConfirmation = false
    @State private var gameStartTime: Date?
    
    @Namespace private var buttonNamespace
    @State private var currentTime: TimeInterval = 0
    @State private var finalTime: TimeInterval = 0
    
    @AppStorage("bestTime") private var bestTime: Double = 0
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (follows system appearance)
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                // Game Board
                if !cells.isEmpty {
                    GameBoardView(
                        cells: cells,
                        selectedCells: selectedCells,
                        isGameActive: isPlaying,  // Pass game state
                        onCellTapped: handleCellTap,
                        availableSize: CGSize(
                            width: geometry.size.width,
                            height: geometry.size.height - 150
                        )
                    )
                    .offset(y: -80)
                }
                
                // Bottom Controls (hidden when completed)
                if !isCompleted {
                    VStack {
                        Spacer()
                        
                        // Timer (only visible when playing)
                        if isPlaying {
                            Text(formatTime(currentTime))
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 8)
                        }
                        
                        // 3 Buttons: Play/Restart (center), Yes (left), No (right)
                        ZStack {
                            GlassEffectContainer(spacing: 40.0) {
                                if showRestartConfirmation{
                                    
                                    HStack
                                    {
                                        // Yes button - starts at center, moves left when visible
                                        Button {
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                showRestartConfirmation = false
                                                restartGame()
                                            }
                                        } label: {
                                            Label("Yes", systemImage: "checkmark")
                                                .font(.headline)
                                                .frame(width: 150)
                                                .padding(.vertical, 16)
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundStyle(.green)
                                        .glassEffect(.regular)
                                        .offset(x: showRestartConfirmation ? -10 : 80)
                                        .opacity(showRestartConfirmation ? 1 : 0)
                                        .allowsHitTesting(showRestartConfirmation)
                                        
                                        // No button - starts at center, moves right when visible
                                        Button {
                                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                                showRestartConfirmation = false
                                            }
                                        } label: {
                                            Label("No", systemImage: "xmark")
                                                .font(.headline)
                                                .frame(width: 150)
                                                .padding(.vertical, 16)
                                        }
                                        .buttonStyle(.plain)
                                        .foregroundStyle(.red)
                                        .glassEffect(.regular)
                                        .offset(x: showRestartConfirmation ? 10 : -80)
                                        .opacity(showRestartConfirmation ? 1 : 0)
                                        .allowsHitTesting(showRestartConfirmation)
                                    }
                                }else{
                                
                                
                                // Play/Restart button - visible when not in confirmation
                                Button {
                                    if isPlaying {
                                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                            showRestartConfirmation = true
                                        }
                                    } else {
                                        startGame()
                                    }
                                } label: {
                                    Label(isPlaying ? "Restart" : "Play", systemImage: isPlaying ? "arrow.clockwise" : "play.fill")
                                        .font(.headline)
                                        .frame(width: 150)
                                        .padding(.vertical, 16)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.primary)
                                .glassEffect(.regular)
                                .opacity(showRestartConfirmation ? 0 : 1)
                                .allowsHitTesting(!showRestartConfirmation)
                            }
                        
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                    }
                }
                
                // Completion Overlay
                if isCompleted {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.yellow)
                        
                        Text("Completed!")
                            .font(.largeTitle.bold())
                        
                        Text(formatTime(finalTime))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                        
                        if isNewHighScore {
                            Label("New Best Time!", systemImage: "star.fill")
                                .font(.headline)
                                .foregroundStyle(.yellow)
                        } else if bestTime > 0 {
                            Text("Best: \(formatTime(bestTime))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Button {
                            restartGame()
                        } label: {
                            Label("Play Again", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    }
                    .padding(40)
                }
            }
        }
        .onAppear {
            prepareBoard()
        }
        .onReceive(timer) { _ in
            if isPlaying, let startTime = gameStartTime {
                currentTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func prepareBoard() {
        var newCells = GridCalculator.createCells()
        let generator = MapGenerator(cells: newCells)
        newCells = generator.generateBoard()
        
        cells = newCells
        selectedCells = []
        updateCellSelectability()
    }
    
    private func startGame() {
        // Don't generate new board - use the existing one
        isCompleted = false
        isNewHighScore = false
        isPlaying = true
        gameStartTime = Date()
        currentTime = 0
    }
    
    private func restartGame() {
        isPlaying = false
        isCompleted = false
        isNewHighScore = false
        gameStartTime = nil
        currentTime = 0
        prepareBoard()  // Generate new board on restart
    }
    
    private func completeGame() {
        isPlaying = false
        isCompleted = true
        finalTime = currentTime
        
        // Check for high score
        if bestTime == 0 || finalTime < bestTime {
            bestTime = finalTime
            isNewHighScore = true
        }
    }
    
    private func checkWinCondition() {
        let remainingAtoms = cells.filter { !$0.contains.isEmpty && $0.contains != "ph" }
        
        if remainingAtoms.isEmpty {
            completeGame()
        }
    }
    
    private func handleCellTap(_ cellId: Int) {
        guard isPlaying else { return }
        
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
                var updatedCells = cells
                for id in selectedCells {
                    if let index = updatedCells.firstIndex(where: { $0.id == id }) {
                        updatedCells[index].contains = ""
                    }
                }
                cells = updatedCells
                selectedCells.removeAll()
                updateCellSelectability()
                checkWinCondition()
            } else if selectedAtoms.count > 1 && !selectedAtoms.contains("quintessence") {
                selectedCells.removeAll()
            }
        } else if selectedCells.count == 1 {
            let selectedAtom = cells.first(where: { $0.id == Array(selectedCells)[0] })?.contains ?? ""
            if selectedAtom == "gold" {
                if let id = selectedCells.first,
                   let index = cells.firstIndex(where: { $0.id == id }) {
                    var updatedCells = cells
                    updatedCells[index].contains = ""
                    cells = updatedCells
                    selectedCells.removeAll()
                    updateCellSelectability()
                    checkWinCondition()
                }
            }
        }
        
        if selectedCells.count > 2 {
            let lastSelected = Array(selectedCells).last!
            selectedCells = [lastSelected]
        }
    }
    
    private func canMatch(_ atom1: String, _ atom2: String) -> Bool {
        if atom1 == "gold" || atom2 == "gold" {
            return false
        }
        return MatchingRules.canMatch(atom1, atom2)
    }
    
    private func updateCellSelectability() {
        var updatedCells = cells
        for i in 0..<updatedCells.count {
            var nv = ""
            
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
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, tenths)
    }
}

#Preview {
    ContentView()
}
