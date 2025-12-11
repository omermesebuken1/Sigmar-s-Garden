//
//  DailyChallengeView.swift
//  Sigmar's Garden Map Generator
//
//  Daily challenge mode where everyone solves the same puzzle
//  No timer - just complete it!
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
    
    private var hasCompletedToday: Bool {
        DailyPuzzleGenerator.hasCompletedToday()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    dailyHeader
                    
                    if isLoading {
                        // Loading state
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading puzzle...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 16)
                        Spacer()
                    } else if hasCompletedToday && !isPlaying && !isCompleted {
                        // Already completed today - show completion screen
                        completedTodayView
                    } else if isCompleted {
                        // Just completed - show completion screen
                        completedTodayView
                    } else {
                        // Game content
                        if isPlaying && !cells.isEmpty {
                            AtomCounterView(cells: cells)
                                .padding(.top, 8)
                        }
                        
                        Spacer()
                        
                        // Game board
                        if !cells.isEmpty {
                            GameBoardView(
                                cells: cells,
                                selectedCells: selectedCells,
                                isGameActive: isPlaying,
                                gridSize: DailyPuzzleGenerator.dailyDifficulty.gridSize,
                                onCellTapped: handleCellTap,
                                availableSize: CGSize(
                                    width: geometry.size.width,
                                    height: geometry.size.height * 0.55
                                )
                            )
                        }
                        
                        Spacer()
                        
                        // Start button
                        if !isPlaying && !isCompleted && !isGameLost && !hasCompletedToday {
                            Button {
                                startGame()
                            } label: {
                                Text("Start Daily Challenge")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .padding(.horizontal, 40)
                            .padding(.bottom, 20)
                        }
                    }
                }
                
                // Lose overlay
                if isGameLost {
                    loseOverlay
                }
            }
        }
        .task {
            await loadDailyPuzzle()
            remainingTime = DailyPuzzleGenerator.timeUntilNextPuzzle()
            streakManager.checkAndApplyFreezeIfNeeded()
        }
        .onReceive(countdownTimer) { _ in
            remainingTime = DailyPuzzleGenerator.timeUntilNextPuzzle()
        }
    }
    
    // MARK: - Subviews
    
    private var dailyHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text("Daily Challenge")
                    .font(.title2.bold())
                
                Spacer()
                
                // Freeze indicator
                HStack(spacing: 4) {
                    Image(systemName: "snowflake")
                        .foregroundStyle(.cyan)
                    Text("\(streakManager.getFreezeCount())/\(StreakManager.maxFreezes)")
                        .font(.caption.bold())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.cyan.opacity(0.2))
                .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Date display
            Text(formattedDate())
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                
                Text("Try again tomorrow!")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 8) {
                    Text("Next puzzle in")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(DailyPuzzleGenerator.formatRemainingTime(remainingTime))
                        .font(.system(.title3, design: .monospaced))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .opacity(loseOverlayOpacity)
        }
    }
    
    // MARK: - Game Logic
    
    private func loadDailyPuzzle() async {
        // Check cache first for instant loading
        if let cached = DailyPuzzleGenerator.getCachedPuzzle() {
            cells = cached
            updateCellSelectability()
            isLoading = false
            return
        }
        
        // Generate async
        let generatedCells = await DailyPuzzleGenerator.generateDailyPuzzleAsync()
        cells = generatedCells
        updateCellSelectability()
        isLoading = false
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
        winOverlayOpacity = 0
        
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
        loseOverlayOpacity = 0
        
        // Mark as attempted so they can't retry
        DailyPuzzleGenerator.markCompleted()
        
        withAnimation(.easeIn(duration: 1.2)) {
            loseOverlayOpacity = 0.9
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
