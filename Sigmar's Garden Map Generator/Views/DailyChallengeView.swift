//
//  DailyChallengeView.swift
//  Sigmar's Garden Map Generator
//
//  Daily challenge mode where everyone solves the same puzzle
//  No timer - state persists across tab switches and app restarts
//

import SwiftUI
import Combine
import GameKit

struct DailyChallengeView: View {
    @State private var cells: [Cell] = []
    @State private var selectedCells: Set<Int> = []
    @State private var isPlaying = false
    @State private var isCompleted = false
    @State private var isGameLost = false
    @State private var isLoading = true
    @State private var loseOverlayOpacity: Double = 0
    @State private var winOverlayOpacity: Double = 0
    
    @StateObject private var gameCenterManager = GameCenterManager.shared
    @StateObject private var streakManager = StreakManager.shared
    
    @State private var remainingTime: TimeInterval = 0
    
    let countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // State persistence keys
    private let cellsKey = "dailyGameCells"
    private let isPlayingKey = "dailyGameIsPlaying"
    private let isGameLostKey = "dailyGameIsLost"
    private let gameStateDate = "dailyGameStateDate"
    
    private var hasCompletedToday: Bool {
        DailyPuzzleGenerator.hasCompletedToday()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (follows system appearance)
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Daily Header - same style as ContentView picker
                    if !isPlaying && !isCompleted && !isGameLost && !hasCompletedToday && !isLoading {
                        dailyHeader
                    }
                    
                    // Atom Counter Bar (top)
                    if isPlaying && !cells.isEmpty {
                        AtomCounterView(cells: cells)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                
                // Game Board
                if !cells.isEmpty && !isCompleted && !hasCompletedToday && !isLoading {
                    GameBoardView(
                        cells: cells,
                        selectedCells: selectedCells,
                        isGameActive: isPlaying,
                        gridSize: DailyPuzzleGenerator.dailyDifficulty.gridSize,
                        onCellTapped: handleCellTap,
                        availableSize: CGSize(
                            width: geometry.size.width,
                            height: geometry.size.height - 150
                        )
                    )
                    .offset(y: -50)
                }
                
                // Bottom Controls (hidden when completed or lost or loading)
                if !isCompleted && !isGameLost && !hasCompletedToday && !isLoading {
                    VStack {
                        Spacer()
                        
                        // Start button - same style as ContentView
                        if !isPlaying {
                            GlassEffectContainer(spacing: 40.0) {
                                Button {
                                    startGame()
                                } label: {
                                    Label("Start", systemImage: "play.fill")
                                        .font(.headline)
                                        .frame(width: 150)
                                        .padding(.vertical, 16)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.primary)
                                .glassEffect(.regular)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 100)
                        }
                    }
                }
                
                // Loading overlay
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading puzzle...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 16)
                        Spacer()
                    }
                }
                
                // Completed screen overlay
                if (hasCompletedToday && !isPlaying && !isGameLost) || isCompleted {
                    completedTodayView
                }
                
                // Lose overlay
                if isGameLost {
                    loseOverlay
                }
            }
        }
        .task {
            // Immediate sync updates
            remainingTime = DailyPuzzleGenerator.timeUntilNextPuzzle()
            streakManager.checkAndApplyFreezeIfNeeded()
            
            // Only load game state if cells are empty (not already loaded)
            guard cells.isEmpty else { return }
            await loadGameState()
        }
        .onReceive(countdownTimer) { _ in
            remainingTime = DailyPuzzleGenerator.timeUntilNextPuzzle()
        }
        .onChange(of: cells) { _, _ in
            saveGameState()
        }
        .onChange(of: isPlaying) { _, _ in
            saveGameState()
        }
        .onChange(of: isGameLost) { _, _ in
            saveGameState()
        }
    }
    
    // MARK: - State Persistence
    
    private func loadGameState() async {
        // Check if saved state is from today
        let savedDate = UserDefaults.standard.double(forKey: gameStateDate)
        let isFromToday = savedDate > 0 && Calendar.current.isDateInToday(Date(timeIntervalSince1970: savedDate))
        
        // Load saved state if from today
        if isFromToday {
            if let cellsData = UserDefaults.standard.data(forKey: cellsKey),
               let savedCells = try? JSONDecoder().decode([Cell].self, from: cellsData) {
                await MainActor.run {
                    cells = savedCells
                    isPlaying = UserDefaults.standard.bool(forKey: isPlayingKey)
                    isGameLost = UserDefaults.standard.bool(forKey: isGameLostKey)
                    updateCellSelectability()
                    
                    // If game was lost, restore lose overlay animation
                    if isGameLost {
                        loseOverlayOpacity = 0.9
                    }
                    
                    isLoading = false
                }
                return
            }
        }
        
        // Otherwise load fresh puzzle
        await loadDailyPuzzle()
    }
    
    private func saveGameState() {
        guard !cells.isEmpty else { return }
        
        // Save cells
        if let cellsData = try? JSONEncoder().encode(cells) {
            UserDefaults.standard.set(cellsData, forKey: cellsKey)
        }
        
        // Save game state
        UserDefaults.standard.set(isPlaying, forKey: isPlayingKey)
        UserDefaults.standard.set(isGameLost, forKey: isGameLostKey)
        
        // Save date
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: gameStateDate)
    }
    
    private func clearGameState() {
        UserDefaults.standard.removeObject(forKey: cellsKey)
        UserDefaults.standard.removeObject(forKey: isPlayingKey)
        UserDefaults.standard.removeObject(forKey: isGameLostKey)
        UserDefaults.standard.removeObject(forKey: gameStateDate)
    }
    
    // MARK: - Subviews
    
    private var dailyHeader: some View {
        HStack(spacing: 12) {
            // Left: Calendar icon + Difficulty badge
            HStack(spacing: 8) {
                Image(systemName: "calendar.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                
                Text(DailyPuzzleGenerator.dailyDifficulty.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(difficultyColor(for: DailyPuzzleGenerator.dailyDifficulty))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(difficultyColor(for: DailyPuzzleGenerator.dailyDifficulty).opacity(0.2))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            // Right: Freeze indicator
            HStack(spacing: 4) {
                Image(systemName: "snowflake")
                    .font(.subheadline)
                    .foregroundStyle(.cyan)
                Text("\(streakManager.getFreezeCount())/\(StreakManager.maxFreezes)")
                    .font(.subheadline.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.cyan.opacity(0.2))
            .clipShape(Capsule())
        }
        .padding(.horizontal, 40)
        .padding(.top, 16)
    }
    
    private func difficultyColor(for difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
    
    private var completedTodayView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                
                // Completion badge
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 70))
                    .foregroundStyle(.green)
                
                Text("Completed!")
                    .font(.title.bold())
                
                // Last 5 days streak visualization
                streakVisualization
                
                // Streak info cards
                HStack(spacing: 16) {
                    InfoCard(
                        title: "Current Streak",
                        value: "\(streakManager.getDailyStreak())",
                        unit: "days",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    InfoCard(
                        title: "Freezes",
                        value: "\(streakManager.getFreezeCount())",
                        unit: "/ \(StreakManager.maxFreezes)",
                        icon: "snowflake",
                        color: .cyan
                    )
                }
                .padding(.horizontal)
                
                // Next puzzle countdown
                VStack(spacing: 8) {
                    Text("Next puzzle in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(DailyPuzzleGenerator.formatRemainingTime(remainingTime))
                        .font(.system(.title, design: .monospaced))
                        .foregroundStyle(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
    }
    
    private var streakVisualization: some View {
        VStack(spacing: 12) {
            Text("Last 5 Days")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 16) {
                ForEach(streakManager.getLast5DaysStatus(), id: \.date) { item in
                    VStack(spacing: 6) {
                        // Icon based on status
                        statusIcon(for: item.status)
                            .font(.title)
                        
                        // Day label
                        Text(dayLabel(for: item.date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func statusIcon(for status: DayStatus) -> some View {
        switch status {
        case .completed:
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
        case .frozen:
            Image(systemName: "snowflake")
                .foregroundStyle(.cyan)
        case .missed:
            Image(systemName: "flame")
                .foregroundStyle(.gray.opacity(0.4))
        case .today:
            Image(systemName: "flame")
                .foregroundStyle(.orange.opacity(0.5))
        case .future:
            Image(systemName: "circle.dotted")
                .foregroundStyle(.gray.opacity(0.3))
        }
    }
    
    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }
    }
    
    private var loseOverlay: some View {
        ZStack {
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
                
                Text("Try again!")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                // Restart button - same style as ContentView
                GlassEffectContainer(spacing: 40.0) {
                    Button {
                        restartGame()
                    } label: {
                        Label("Restart", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .frame(width: 150)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.primary)
                    .glassEffect(.regular)
                }
                .padding(.horizontal, 24)
                
                // Next puzzle countdown (less prominent)
                VStack(spacing: 4) {
                    Text("Next puzzle in")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(DailyPuzzleGenerator.formatRemainingTime(remainingTime))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .opacity(loseOverlayOpacity)
        }
    }
    
    // MARK: - Game Logic
    
    private func loadDailyPuzzle() async {
        // Check cache first for instant loading
        if let cached = DailyPuzzleGenerator.getCachedPuzzle() {
            await MainActor.run {
                cells = cached
                updateCellSelectability()
                isLoading = false
            }
            return
        }
        
        // Generate async
        let generatedCells = await DailyPuzzleGenerator.generateDailyPuzzleAsync()
        await MainActor.run {
            cells = generatedCells
            updateCellSelectability()
            isLoading = false
        }
    }
    
    private func startGame() {
        isPlaying = true
        isCompleted = false
        isGameLost = false
        selectedCells = []
    }
    
    private func completeGame() {
        isPlaying = false
        isCompleted = true
        isGameLost = false // Ensure mutually exclusive with lose state
        winOverlayOpacity = 0
        
        // Clear saved state
        clearGameState()
        
        // Mark daily as completed
        DailyPuzzleGenerator.markCompleted()
        
        // Record daily streak
        streakManager.recordDailyPlay()
        
        // Submit daily streak to Game Center
        let longestDailyStreak = streakManager.getLongestDailyStreak()
        Task {
            await gameCenterManager.submitDailyStreak(longestDailyStreak)
        }
    }
    
    private func loseGame() {
        isPlaying = false
        isGameLost = true
        isCompleted = false // Ensure mutually exclusive with completed state
        loseOverlayOpacity = 0
        
        withAnimation(.easeIn(duration: 1.2)) {
            loseOverlayOpacity = 0.9
        }
    }
    
    private func restartGame() {
        // Clear saved game state (so we don't reload partial game)
        UserDefaults.standard.removeObject(forKey: cellsKey)
        UserDefaults.standard.removeObject(forKey: isPlayingKey)
        UserDefaults.standard.removeObject(forKey: isGameLostKey)
        // Note: Keep gameStateDate so we know it's today's puzzle
        
        // Reset UI state
        isGameLost = false
        isPlaying = true
        loseOverlayOpacity = 0
        selectedCells = []
        
        // Reload fresh daily puzzle from cache
        if let cached = DailyPuzzleGenerator.getCachedPuzzle() {
            cells = cached
            updateCellSelectability()
        } else {
            // If cache is empty, reload async
            Task {
                await loadDailyPuzzle()
                await MainActor.run {
                    isPlaying = true
                }
            }
        }
    }
    
    private func checkWinCondition() {
        let remainingAtoms = cells.filter { !$0.contains.isEmpty && $0.contains != "ph" }
        
        if remainingAtoms.isEmpty {
            completeGame()
        } else {
            if !hasLegalMoves() {
                loseGame()
            }
        }
    }
    
    private func hasLegalMoves() -> Bool {
        let selectableCells = cells.filter { 
            $0.selectable && !$0.contains.isEmpty && $0.contains != "ph" 
        }
        
        if selectableCells.contains(where: { $0.contains == "gold" }) {
            return true
        }
        
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
    
    // MARK: - Helpers
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DailyChallengeView()
}
