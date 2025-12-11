//
//  StatsView.swift
//  Sigmar's Garden Map Generator
//
//  Statistics view showing all player stats
//

import SwiftUI
import GameKit

struct StatsView: View {
    @StateObject private var gameCenterManager = GameCenterManager.shared
    @StateObject private var streakManager = StreakManager.shared
    
    // Best times
    @AppStorage("bestTime_easy") private var bestTimeEasy: Double = 0
    @AppStorage("bestTime_medium") private var bestTimeMedium: Double = 0
    @AppStorage("bestTime_hard") private var bestTimeHard: Double = 0
    
    // Solve counts
    @AppStorage("solveCount_easy") private var solveCountEasy: Int = 0
    @AppStorage("solveCount_medium") private var solveCountMedium: Int = 0
    @AppStorage("solveCount_hard") private var solveCountHard: Int = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Daily Streak Section
                    dailyStreakSection
                    
                    // Difficulty Stats Section
                    difficultyStatsSection
                    
                    // Game Center Button
                    gameCenterButton
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
        .onAppear {
            gameCenterManager.authenticate()
        }
    }
    
    // MARK: - Daily Streak Section
    
    private var dailyStreakSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("Daily Challenge")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 16) {
                // Current Streak
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                    
                    Text("\(streakManager.getDailyStreak())")
                        .font(.title.bold())
                    
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Longest Streak
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.title)
                        .foregroundStyle(.yellow)
                    
                    Text("\(streakManager.getLongestDailyStreak())")
                        .font(.title.bold())
                    
                    Text("Best Streak")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Streak Freezes
                VStack(spacing: 8) {
                    Image(systemName: "snowflake")
                        .font(.title)
                        .foregroundStyle(.cyan)
                    
                    Text("\(streakManager.getFreezeCount())/\(StreakManager.maxFreezes)")
                        .font(.title.bold())
                    
                    Text("Freezes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.cyan.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Difficulty Stats Section
    
    private var difficultyStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.green)
                Text("Free Play Stats")
                    .font(.headline)
                Spacer()
            }
            
            // Stats grid
            HStack(spacing: 12) {
                difficultyColumn(
                    title: "Easy",
                    color: .green,
                    bestTime: bestTimeEasy,
                    solveCount: solveCountEasy,
                    avgTime: streakManager.getAverageTime(for: .easy)
                )
                
                difficultyColumn(
                    title: "Medium",
                    color: .orange,
                    bestTime: bestTimeMedium,
                    solveCount: solveCountMedium,
                    avgTime: streakManager.getAverageTime(for: .medium)
                )
                
                difficultyColumn(
                    title: "Hard",
                    color: .red,
                    bestTime: bestTimeHard,
                    solveCount: solveCountHard,
                    avgTime: streakManager.getAverageTime(for: .hard)
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func difficultyColumn(
        title: String,
        color: Color,
        bestTime: Double,
        solveCount: Int,
        avgTime: TimeInterval
    ) -> some View {
        VStack(spacing: 12) {
            // Title
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            
            Divider()
            
            // Best Time
            VStack(spacing: 4) {
                Text("Best")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(bestTime > 0 ? formatTime(bestTime) : "--:--")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.semibold)
            }
            
            // Solve Count
            VStack(spacing: 4) {
                Text("Solves")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(solveCount)")
                    .font(.callout.bold())
            }
            
            // Average Time
            VStack(spacing: 4) {
                Text("Average")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(avgTime > 0 ? formatTime(avgTime) : "--:--")
                    .font(.system(.caption, design: .monospaced))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Game Center Button
    
    private var gameCenterButton: some View {
        Button {
            gameCenterManager.showGameCenterDashboard()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "gamecontroller.fill")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Game Center")
                        .font(.headline)
                    Text("View leaderboards & achievements")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(!gameCenterManager.isAuthenticated)
        .opacity(gameCenterManager.isAuthenticated ? 1 : 0.5)
    }
    
    // MARK: - Helpers
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, tenths)
    }
}

#Preview {
    StatsView()
}

