//
//  LeaderboardsView.swift
//  Sigmar's Garden Map Generator
//

import SwiftUI
import GameKit

struct LeaderboardsView: View {
    @StateObject private var gameCenterManager = GameCenterManager.shared
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var bestTimeEntries: [GKLeaderboard.Entry] = []
    @State private var solveCountEntries: [GKLeaderboard.Entry] = []
    @State private var localBestTimeEntry: GKLeaderboard.Entry?
    @State private var localSolveCountEntry: GKLeaderboard.Entry?
    @State private var isLoading = false
    
    // Local stats from AppStorage
    @AppStorage("bestTime_easy") private var bestTimeEasy: Double = 0
    @AppStorage("bestTime_medium") private var bestTimeMedium: Double = 0
    @AppStorage("bestTime_hard") private var bestTimeHard: Double = 0
    @AppStorage("solveCount_easy") private var solveCountEasy: Int = 0
    @AppStorage("solveCount_medium") private var solveCountMedium: Int = 0
    @AppStorage("solveCount_hard") private var solveCountHard: Int = 0
    
    private var localBestTime: Double {
        switch selectedDifficulty {
        case .easy: return bestTimeEasy
        case .medium: return bestTimeMedium
        case .hard: return bestTimeHard
        }
    }
    
    private var localSolveCount: Int {
        switch selectedDifficulty {
        case .easy: return solveCountEasy
        case .medium: return solveCountMedium
        case .hard: return solveCountHard
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Difficulty Picker
                Picker("Difficulty", selection: $selectedDifficulty) {
                    ForEach(Difficulty.allCases) { difficulty in
                        Text(difficulty.displayName).tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .onChange(of: selectedDifficulty) { _, _ in
                    Task {
                        await loadLeaderboards()
                    }
                }
                
                if !gameCenterManager.isAuthenticated {
                    // Not authenticated view
                    VStack(spacing: 20) {
                        Spacer()
                        
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        
                        Text("Not Connected to Game Center")
                            .font(.title2.bold())
                        
                        Text("Sign in to Game Center to view leaderboards.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Show local stats
                        localStatsSection
                        
                        Spacer()
                    }
                } else if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading...")
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Your Stats Section
                            yourStatsSection
                            
                            // Best Time Leaderboard
                            leaderboardSection(
                                title: "Best Time",
                                icon: "timer",
                                entries: bestTimeEntries,
                                type: .bestTime
                            )
                            
                            // Solve Count Leaderboard
                            leaderboardSection(
                                title: "Most Solves",
                                icon: "trophy.fill",
                                entries: solveCountEntries,
                                type: .solveCount
                            )
                        }
                        .padding()
                    }
                }
            }
                .navigationTitle("Ranks")
            .toolbar {
                if gameCenterManager.isAuthenticated {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            gameCenterManager.showGameCenterDashboard()
                        } label: {
                            Image(systemName: "gamecontroller.fill")
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadLeaderboards()
            }
        }
    }
    
    // MARK: - Your Stats Section
    
    private var yourStatsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(.blue)
                Text("Your Stats")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Best Time Card
                StatCard(
                    title: "Best Time",
                    value: localBestTime > 0 ? formatTime(localBestTime) : "--:--.-",
                    icon: "timer",
                    color: .orange
                )
                
                // Solve Count Card
                StatCard(
                    title: "Total Solves",
                    value: "\(localSolveCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            // Global rank if available
            if let timeEntry = localBestTimeEntry {
                HStack {
                    Text("Time Rank:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("#\(timeEntry.rank)")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                    Spacer()
                }
            }
            
            if let countEntry = localSolveCountEntry {
                HStack {
                    Text("Solve Rank:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("#\(countEntry.rank)")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var localStatsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Local Stats")
                    .font(.headline)
            }
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Best Time",
                    value: localBestTime > 0 ? formatTime(localBestTime) : "--:--.-",
                    icon: "timer",
                    color: .orange
                )
                
                StatCard(
                    title: "Total Solves",
                    value: "\(localSolveCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding()
    }
    
    // MARK: - Leaderboard Section
    
    private func leaderboardSection(
        title: String,
        icon: String,
        entries: [GKLeaderboard.Entry],
        type: LeaderboardType
    ) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(type == .bestTime ? .orange : .green)
                Text(title)
                    .font(.headline)
                Spacer()
                
                Button {
                    gameCenterManager.showLeaderboard(for: selectedDifficulty, type: type)
                } label: {
                    Text("See All")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            
            if entries.isEmpty {
                Text("No data yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                ForEach(entries.prefix(5), id: \.rank) { entry in
                    LeaderboardEntryRow(entry: entry, type: type)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Functions
    
    private func loadLeaderboards() async {
        guard gameCenterManager.isAuthenticated else { return }
        
        isLoading = true
        
        async let timeEntries = gameCenterManager.loadLeaderboard(
            for: selectedDifficulty,
            type: .bestTime
        )
        async let countEntries = gameCenterManager.loadLeaderboard(
            for: selectedDifficulty,
            type: .solveCount
        )
        async let localTime = gameCenterManager.loadLocalPlayerEntry(
            for: selectedDifficulty,
            type: .bestTime
        )
        async let localCount = gameCenterManager.loadLocalPlayerEntry(
            for: selectedDifficulty,
            type: .solveCount
        )
        
        bestTimeEntries = await timeEntries ?? []
        solveCountEntries = await countEntries ?? []
        localBestTimeEntry = await localTime
        localSolveCountEntry = await localCount
        
        isLoading = false
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, tenths)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3.bold())
            
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

// MARK: - Leaderboard Entry Row

struct LeaderboardEntryRow: View {
    let entry: GKLeaderboard.Entry
    let type: LeaderboardType
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(entry.rank)")
                .font(.headline)
                .foregroundStyle(rankColor)
                .frame(width: 40, alignment: .leading)
            
            // Player name
            Text(entry.player.displayName)
                .font(.subheadline)
                .lineLimit(1)
            
            Spacer()
            
            // Score
            Text(formattedScore)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(entry.rank <= 3 ? rankColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }
    
    private var formattedScore: String {
        switch type {
        case .bestTime:
            // Score is in centiseconds (0.01 second precision)
            let timeInSeconds = Double(entry.score) / 100.0
            let minutes = Int(timeInSeconds) / 60
            let seconds = Int(timeInSeconds) % 60
            let hundredths = Int((timeInSeconds.truncatingRemainder(dividingBy: 1)) * 100)
            return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
        case .solveCount:
            return "\(entry.score)"
        }
    }
}

#Preview {
    LeaderboardsView()
}
