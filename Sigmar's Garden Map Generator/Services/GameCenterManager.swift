//
//  GameCenterManager.swift
//  Sigmar's Garden Map Generator
//
//  Game Center integration for leaderboards
//

import Foundation
import GameKit
import SwiftUI
import Combine

@MainActor
class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()
    
    @Published var isAuthenticated = false
    @Published var localPlayer: GKLocalPlayer?
    @Published var authenticationError: Error?
    
    private init() {}
    
    // MARK: - Authentication
    
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let error = error {
                    self?.authenticationError = error
                    self?.isAuthenticated = false
                    print("Game Center authentication error: \(error.localizedDescription)")
                    return
                }
                
                if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                    self?.localPlayer = GKLocalPlayer.local
                    print("Game Center authenticated: \(GKLocalPlayer.local.displayName)")
                } else {
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    // MARK: - Score Submission
    
    /// Submit best time score (in centiseconds for Game Center display)
    func submitTime(_ time: TimeInterval, for difficulty: Difficulty) async {
        guard isAuthenticated else {
            print("Not authenticated to Game Center")
            return
        }
        
        let leaderboardID = difficulty.bestTimeLeaderboardID
        let scoreInCentiseconds = Int(time * 100) // Convert to centiseconds (0.01 second precision)
        
        do {
            try await GKLeaderboard.submitScore(
                scoreInCentiseconds,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
            print("Submitted time score \(scoreInCentiseconds) centiseconds to \(leaderboardID)")
        } catch {
            print("Failed to submit time score: \(error.localizedDescription)")
        }
    }
    
    /// Submit solve count
    func submitSolveCount(_ count: Int, for difficulty: Difficulty) async {
        guard isAuthenticated else {
            print("Not authenticated to Game Center")
            return
        }
        
        let leaderboardID = difficulty.solveCountLeaderboardID
        
        do {
            try await GKLeaderboard.submitScore(
                count,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [leaderboardID]
            )
            print("Submitted solve count \(count) to \(leaderboardID)")
        } catch {
            print("Failed to submit solve count: \(error.localizedDescription)")
        }
    }
    
    /// Submit daily streak score and check achievements
    func submitDailyStreak(_ streak: Int) async {
        guard isAuthenticated else {
            print("Not authenticated to Game Center")
            return
        }
        
        // Submit to leaderboard
        do {
            try await GKLeaderboard.submitScore(
                streak,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [LeaderboardID.dailyStreak]
            )
            print("Submitted daily streak \(streak)")
        } catch {
            print("Failed to submit daily streak: \(error.localizedDescription)")
        }
        
        // Check streak achievements
        await checkStreakAchievements(streak: streak)
    }
    
    /// Check and report daily streak achievements
    func checkStreakAchievements(streak: Int) async {
        // 3 days
        if streak >= 3 {
            await reportAchievement(AchievementID.streak3Days)
        } else {
            await reportAchievement(AchievementID.streak3Days, percentComplete: Double(streak) / 3.0 * 100.0)
        }
        
        // 7 days (1 week)
        if streak >= 7 {
            await reportAchievement(AchievementID.streak7Days)
        } else {
            await reportAchievement(AchievementID.streak7Days, percentComplete: Double(streak) / 7.0 * 100.0)
        }
        
        // 30 days (1 month)
        if streak >= 30 {
            await reportAchievement(AchievementID.streak30Days)
        } else {
            await reportAchievement(AchievementID.streak30Days, percentComplete: Double(streak) / 30.0 * 100.0)
        }
        
        // 90 days (3 months)
        if streak >= 90 {
            await reportAchievement(AchievementID.streak90Days)
        } else {
            await reportAchievement(AchievementID.streak90Days, percentComplete: Double(streak) / 90.0 * 100.0)
        }
        
        // 180 days (6 months)
        if streak >= 180 {
            await reportAchievement(AchievementID.streak180Days)
        } else {
            await reportAchievement(AchievementID.streak180Days, percentComplete: Double(streak) / 180.0 * 100.0)
        }
        
        // 365 days (1 year)
        if streak >= 365 {
            await reportAchievement(AchievementID.streak365Days)
        } else {
            await reportAchievement(AchievementID.streak365Days, percentComplete: Double(streak) / 365.0 * 100.0)
        }
    }
    
    // MARK: - Achievements
    
    /// Report achievement progress (0.0 to 100.0)
    func reportAchievement(_ achievementID: String, percentComplete: Double = 100.0) async {
        guard isAuthenticated else {
            print("Not authenticated to Game Center")
            return
        }
        
        let achievement = GKAchievement(identifier: achievementID)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true
        
        do {
            try await GKAchievement.report([achievement])
            print("Reported achievement \(achievementID) at \(percentComplete)%")
        } catch {
            print("Failed to report achievement: \(error.localizedDescription)")
        }
    }
    
    /// Check and report achievements after completing a game
    func checkAchievements(
        difficulty: Difficulty,
        time: TimeInterval,
        easySolves: Int,
        mediumSolves: Int,
        hardSolves: Int
    ) async {
        let totalSolves = easySolves + mediumSolves + hardSolves
        
        // First Win
        if totalSolves == 1 {
            await reportAchievement(AchievementID.firstWin)
        }
        
        // Speedrun achievements (under 60 seconds)
        if time < 60 {
            switch difficulty {
            case .easy:
                await reportAchievement(AchievementID.easySpeedrun)
            case .medium:
                await reportAchievement(AchievementID.mediumSpeedrun)
            case .hard:
                await reportAchievement(AchievementID.hardSpeedrun)
            }
        }
        
        // Master achievements (10 solves per difficulty)
        switch difficulty {
        case .easy:
            if easySolves >= 10 {
                await reportAchievement(AchievementID.easyMaster)
            } else {
                await reportAchievement(AchievementID.easyMaster, percentComplete: Double(easySolves) * 10.0)
            }
        case .medium:
            if mediumSolves >= 10 {
                await reportAchievement(AchievementID.mediumMaster)
            } else {
                await reportAchievement(AchievementID.mediumMaster, percentComplete: Double(mediumSolves) * 10.0)
            }
        case .hard:
            if hardSolves >= 10 {
                await reportAchievement(AchievementID.hardMaster)
            } else {
                await reportAchievement(AchievementID.hardMaster, percentComplete: Double(hardSolves) * 10.0)
            }
        }
        
        // Perfectionist (100 total solves)
        if totalSolves >= 100 {
            await reportAchievement(AchievementID.perfectionist)
        } else {
            await reportAchievement(AchievementID.perfectionist, percentComplete: Double(totalSolves))
        }
    }
    
    // MARK: - Leaderboard Access
    
    /// Load leaderboard entries for a specific difficulty and type
    func loadLeaderboard(
        for difficulty: Difficulty,
        type: LeaderboardType,
        scope: GKLeaderboard.PlayerScope = .global,
        timeScope: GKLeaderboard.TimeScope = .allTime,
        range: NSRange = NSRange(location: 1, length: 10)
    ) async -> [GKLeaderboard.Entry]? {
        guard isAuthenticated else { return nil }
        
        let leaderboardID: String
        switch type {
        case .bestTime:
            leaderboardID = difficulty.bestTimeLeaderboardID
        case .solveCount:
            leaderboardID = difficulty.solveCountLeaderboardID
        }
        
        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            guard let leaderboard = leaderboards.first else { return nil }
            
            let (_, entries, _) = try await leaderboard.loadEntries(
                for: scope,
                timeScope: timeScope,
                range: range
            )
            
            return entries
        } catch {
            print("Failed to load leaderboard: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Load local player's entry for a specific leaderboard
    func loadLocalPlayerEntry(
        for difficulty: Difficulty,
        type: LeaderboardType
    ) async -> GKLeaderboard.Entry? {
        guard isAuthenticated else { return nil }
        
        let leaderboardID: String
        switch type {
        case .bestTime:
            leaderboardID = difficulty.bestTimeLeaderboardID
        case .solveCount:
            leaderboardID = difficulty.solveCountLeaderboardID
        }
        
        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            guard let leaderboard = leaderboards.first else { return nil }
            
            let (localEntry, _, _) = try await leaderboard.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 1)
            )
            
            return localEntry
        } catch {
            print("Failed to load local player entry: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Game Center UI
    
    /// Show Game Center dashboard
    func showGameCenterDashboard() {
        guard isAuthenticated else { return }
        
        let viewController = GKGameCenterViewController(state: .default)
        viewController.gameCenterDelegate = GameCenterDelegateHandler.shared
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(viewController, animated: true)
        }
    }
    
    /// Show specific leaderboard
    func showLeaderboard(for difficulty: Difficulty, type: LeaderboardType) {
        guard isAuthenticated else { return }
        
        let leaderboardID: String
        switch type {
        case .bestTime:
            leaderboardID = difficulty.bestTimeLeaderboardID
        case .solveCount:
            leaderboardID = difficulty.solveCountLeaderboardID
        }
        
        let viewController = GKGameCenterViewController(
            leaderboardID: leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        viewController.gameCenterDelegate = GameCenterDelegateHandler.shared
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(viewController, animated: true)
        }
    }
}

// MARK: - Leaderboard Type

enum LeaderboardType {
    case bestTime
    case solveCount
}

// MARK: - Achievement IDs

struct AchievementID {
    static let firstWin = "garden.first_win"
    static let easyMaster = "garden.easy_master"
    static let mediumMaster = "garden.medium_master"
    static let hardMaster = "garden.hard_master"
    static let easySpeedrun = "garden.easy_speedrun"
    static let mediumSpeedrun = "garden.medium_speedrun"
    static let hardSpeedrun = "garden.hard_speedrun"
    static let perfectionist = "garden.perfectionist"
    
    // Daily streak achievements
    static let streak3Days = "garden.streak_3days"       // 3 days
    static let streak7Days = "garden.streak_7days"       // 7 days (1 week)
    static let streak30Days = "garden.streak_30days"     // 30 days (1 month)
    static let streak90Days = "garden.streak_90days"     // 90 days (3 months)
    static let streak180Days = "garden.streak_180days"   // 180 days (6 months)
    static let streak365Days = "garden.streak_365days"   // 365 days (1 year)
}

// MARK: - Leaderboard IDs (Daily)

struct LeaderboardID {
    static let dailyStreak = "garden.daily_streak"
}

// MARK: - Game Center Delegate Handler

class GameCenterDelegateHandler: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDelegateHandler()
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

