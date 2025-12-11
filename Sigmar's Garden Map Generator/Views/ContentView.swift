//
//  ContentView.swift
//  Sigmar's Garden Map Generator
//
//  Created by Ömer Faruk Meşebüken on 5.12.2025.
//

import SwiftUI
import Combine
import GameKit

struct ContentView: View {
    @State private var cells: [Cell] = []
    @State private var selectedCells: Set<Int> = []
    @State private var isPlaying = false
    @State private var isCompleted = false
    @State private var isGameLost = false
    @State private var loseOverlayOpacity: Double = 0
    @State private var winOverlayOpacity: Double = 0
    @State private var isNewHighScore = false
    @State private var showRestartConfirmation = false
    @State private var gameStartTime: Date?
    @State private var selectedDifficulty: Difficulty = .easy
    
    // Cache for each difficulty's board state
    @State private var cachedCells: [Difficulty: [Cell]] = [:]
    
    @StateObject private var gameCenterManager = GameCenterManager.shared
    @StateObject private var streakManager = StreakManager.shared
    
    @Namespace private var buttonNamespace
    @State private var currentTime: TimeInterval = 0
    @State private var finalTime: TimeInterval = 0
    
    // Per-difficulty best times
    @AppStorage("bestTime_easy") private var bestTimeEasy: Double = 0
    @AppStorage("bestTime_medium") private var bestTimeMedium: Double = 0
    @AppStorage("bestTime_hard") private var bestTimeHard: Double = 0
    
    // Per-difficulty solve counts
    @AppStorage("solveCount_easy") private var solveCountEasy: Int = 0
    @AppStorage("solveCount_medium") private var solveCountMedium: Int = 0
    @AppStorage("solveCount_hard") private var solveCountHard: Int = 0
    
    private var bestTime: Double {
        get {
            switch selectedDifficulty {
            case .easy: return bestTimeEasy
            case .medium: return bestTimeMedium
            case .hard: return bestTimeHard
            }
        }
    }
    
    private func setBestTime(_ time: Double) {
        switch selectedDifficulty {
        case .easy: bestTimeEasy = time
        case .medium: bestTimeMedium = time
        case .hard: bestTimeHard = time
        }
    }
    
    private func incrementSolveCount() {
        switch selectedDifficulty {
        case .easy: solveCountEasy += 1
        case .medium: solveCountMedium += 1
        case .hard: solveCountHard += 1
        }
    }
    
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (follows system appearance)
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Difficulty Picker (only visible when not playing)
                    if !isPlaying && !isCompleted && !isGameLost {
                        Picker("Difficulty", selection: $selectedDifficulty) {
                            ForEach(Difficulty.allCases) { difficulty in
                                Text(difficulty.displayName).tag(difficulty)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 40)
                        .padding(.top, 16)
                        .onChange(of: selectedDifficulty) { _, _ in
                            loadOrGenerateBoard()
                        }
                    }
                    
                    // Atom Counter Bar (top)
                    if isPlaying && !cells.isEmpty {
                        AtomCounterView(cells: cells)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                
                // Game Board
                if !cells.isEmpty {
                    GameBoardView(
                        cells: cells,
                        selectedCells: selectedCells,
                        isGameActive: isPlaying,
                        gridSize: selectedDifficulty.gridSize,
                        onCellTapped: handleCellTap,
                        availableSize: CGSize(
                            width: geometry.size.width,
                            height: geometry.size.height - 150
                        )
                    )
                    .offset(y: -50)
                }
                
                // Bottom Controls (hidden when completed or lost)
                if !isCompleted && !isGameLost {
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
                
                // Win Overlay - frosting glass effect
                if isCompleted {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(winOverlayOpacity)
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
                    .opacity(winOverlayOpacity)
                    .scaleEffect(0.9 + (winOverlayOpacity * 0.1))
                }
                
                // Lose Overlay - frosting glass effect
                if isGameLost {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(loseOverlayOpacity)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                        
                        Text("No Moves Left!")
                            .font(.largeTitle.bold())
                    
                        Button {
                            restartGame()
                        } label: {
                            Label("Try Again", systemImage: "arrow.clockwise")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.large)
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    }
                    .padding(40)
                    .opacity(loseOverlayOpacity)
                    .scaleEffect(0.9 + (loseOverlayOpacity * 0.1))
                }
            }
        }
        .onAppear {
            // Only generate board if not already loaded (preserves state on tab switch)
            if cells.isEmpty {
                loadOrGenerateBoard()
            }
            gameCenterManager.authenticate()
        }
        .onReceive(timer) { _ in
            if isPlaying, let startTime = gameStartTime {
                currentTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    /// Load board from cache or generate new one if not cached
    private func loadOrGenerateBoard() {
        if let cached = cachedCells[selectedDifficulty] {
            cells = cached
            selectedCells = []
            updateCellSelectability()
        } else {
            generateNewBoard()
        }
    }
    
    /// Generate a fresh board and cache it
    private func generateNewBoard() {
        let gridCalculator = GridCalculator(difficulty: selectedDifficulty)
        var newCells = gridCalculator.createCells()
        let generator = MapGenerator(cells: newCells, difficulty: selectedDifficulty)
        newCells = generator.generateBoard()
        
        cells = newCells
        cachedCells[selectedDifficulty] = newCells
        selectedCells = []
        updateCellSelectability()
    }
    
    private func startGame() {
        // Don't generate new board - use the existing one
        isCompleted = false
        isGameLost = false
        isNewHighScore = false
        isPlaying = true
        gameStartTime = Date()
        currentTime = 0
    }
    
    private func restartGame() {
        isPlaying = false
        isCompleted = false
        isGameLost = false
        loseOverlayOpacity = 0
        winOverlayOpacity = 0
        isNewHighScore = false
        gameStartTime = nil
        currentTime = 0
        generateNewBoard()  // Generate new board on restart
    }
    
    private func completeGame() {
        isPlaying = false
        isCompleted = true
        finalTime = currentTime
        winOverlayOpacity = 0
        
        // Animate the frosting effect
        withAnimation(.easeIn(duration: 1.2)) {
            winOverlayOpacity = 0.9
        }
        
        // Increment solve count
        incrementSolveCount()
        
        // Record time for average calculation
        streakManager.recordTime(finalTime, for: selectedDifficulty)
        
        // Record streak for the current difficulty
        streakManager.recordPlay(for: selectedDifficulty)
        
        // Check for high score
        if bestTime == 0 || finalTime < bestTime {
            setBestTime(finalTime)
            isNewHighScore = true
        }
        
        // Submit to Game Center
        submitScoresToGameCenter()
    }
    
    private func submitScoresToGameCenter() {
        let currentSolveCount: Int
        switch selectedDifficulty {
        case .easy: currentSolveCount = solveCountEasy
        case .medium: currentSolveCount = solveCountMedium
        case .hard: currentSolveCount = solveCountHard
        }
        
        Task {
            // Submit scores
            await gameCenterManager.submitTime(finalTime, for: selectedDifficulty)
            await gameCenterManager.submitSolveCount(currentSolveCount, for: selectedDifficulty)
            
            // Check achievements
            await gameCenterManager.checkAchievements(
                difficulty: selectedDifficulty,
                time: finalTime,
                easySolves: solveCountEasy,
                mediumSolves: solveCountMedium,
                hardSolves: solveCountHard
            )
        }
    }
    
    private func loseGame() {
        isPlaying = false
        isGameLost = true
        loseOverlayOpacity = 0
        
        // Animate the frosting effect
        withAnimation(.easeIn(duration: 1.2)) {
            loseOverlayOpacity = 0.9
        }
    }
    
    private func checkWinCondition() {
        let remainingAtoms = cells.filter { !$0.contains.isEmpty && $0.contains != "ph" }
        
        if remainingAtoms.isEmpty {
            completeGame()
        } else {
            // Check if there are any legal moves left
            if !hasLegalMoves() {
                loseGame()
            }
        }
    }
    
    private func hasLegalMoves() -> Bool {
        // Get all selectable cells with atoms
        let selectableCells = cells.filter { 
            $0.selectable && !$0.contains.isEmpty && $0.contains != "ph" 
        }
        
        // Check if gold is selectable (gold can be taken alone)
        if selectableCells.contains(where: { $0.contains == "gold" }) {
            return true
        }
        
        // Check all pairs of selectable cells for valid matches
        for i in 0..<selectableCells.count {
            for j in (i+1)..<selectableCells.count {
                let atom1 = selectableCells[i].contains
                let atom2 = selectableCells[j].contains
                
                if canMatch(atom1, atom2) {
                    return true
                }
            }
        }
        
        return false
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
