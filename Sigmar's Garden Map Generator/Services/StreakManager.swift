//
//  StreakManager.swift
//  Sigmar's Garden Map Generator
//
//  Manages daily play streaks with freeze system
//

import Foundation
import Combine

// Day status for streak visualization
enum DayStatus: String, Codable {
    case completed    // Green flame - completed
    case frozen       // Blue ice - freeze used
    case missed       // Gray - missed
    case today        // Current day
    case future       // Future day
}

class StreakManager: ObservableObject {
    static let shared = StreakManager()
    
    private let defaults = UserDefaults.standard
    
    // Keys for UserDefaults
    private enum Keys {
        // Difficulty-based streaks (for free play)
        static func lastPlayDate(_ difficulty: Difficulty) -> String { "lastPlayDate_\(difficulty.rawValue)" }
        static func currentStreak(_ difficulty: Difficulty) -> String { "currentStreak_\(difficulty.rawValue)" }
        static func longestStreak(_ difficulty: Difficulty) -> String { "longestStreak_\(difficulty.rawValue)" }
        
        // Daily challenge
        static let lastDailyPlayDate = "lastDailyPlayDate"
        static let currentDailyStreak = "currentDailyStreak"
        static let longestDailyStreak = "longestDailyStreak"
        
        // Streak freeze system
        static let streakFreezeCount = "streakFreezeCount"
        static let totalDaysCompleted = "totalDaysCompleted"
        static let lastFreezeAwardedAt = "lastFreezeAwardedAt" // Total days when last freeze was awarded
        static let dailyHistory = "dailyHistory" // Last 30 days history
        
        // Average time tracking
        static func totalTime(_ difficulty: Difficulty) -> String { "totalTime_\(difficulty.rawValue)" }
    }
    
    // Published properties for UI updates
    @Published var currentDailyStreak: Int = 0
    @Published var streakFreezeCount: Int = 0
    
    // Maximum streak freezes
    static let maxFreezes = 2
    static let daysPerFreeze = 30
    
    private init() {
        loadInitialValues()
        checkAndApplyFreezeIfNeeded()
    }
    
    private func loadInitialValues() {
        currentDailyStreak = defaults.integer(forKey: Keys.currentDailyStreak)
        streakFreezeCount = min(defaults.integer(forKey: Keys.streakFreezeCount), Self.maxFreezes)
    }
    
    // MARK: - Daily Challenge Methods
    
    /// Record a completed daily challenge
    func recordDailyPlay() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayTimestamp = today.timeIntervalSince1970
        
        // Update history
        var history = getDailyHistory()
        history[todayTimestamp] = .completed
        saveDailyHistory(history)
        
        // Update streak
        let lastPlayDate = defaults.double(forKey: Keys.lastDailyPlayDate)
        let lastPlayDay = Date(timeIntervalSince1970: lastPlayDate)
        let lastPlayDayStart = Calendar.current.startOfDay(for: lastPlayDay)
        
        let daysDifference = Calendar.current.dateComponents([.day], from: lastPlayDayStart, to: today).day ?? 0
        
        var currentStreak = defaults.integer(forKey: Keys.currentDailyStreak)
        
        if daysDifference == 0 {
            // Already played today
            if currentStreak == 0 {
                currentStreak = 1
            }
        } else if daysDifference == 1 {
            // Played yesterday (or freeze was used)
            currentStreak += 1
        } else if daysDifference == 2 {
            // Missed one day - check if freeze was used
            let yesterdayTimestamp = Calendar.current.date(byAdding: .day, value: -1, to: today)!.timeIntervalSince1970
            if history[yesterdayTimestamp] == .frozen {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
        } else {
            // More than 2 days gap
            currentStreak = 1
        }
        
        defaults.set(todayTimestamp, forKey: Keys.lastDailyPlayDate)
        defaults.set(currentStreak, forKey: Keys.currentDailyStreak)
        
        // Update longest streak
        let longestStreak = defaults.integer(forKey: Keys.longestDailyStreak)
        if currentStreak > longestStreak {
            defaults.set(currentStreak, forKey: Keys.longestDailyStreak)
        }
        
        // Increment total days completed
        let totalDays = defaults.integer(forKey: Keys.totalDaysCompleted) + 1
        defaults.set(totalDays, forKey: Keys.totalDaysCompleted)
        
        // Check if player earned a new freeze
        checkAndAwardFreeze(totalDays: totalDays)
        
        // Update published values
        currentDailyStreak = currentStreak
    }
    
    /// Check and automatically apply freeze if yesterday was missed
    func checkAndApplyFreezeIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let yesterdayTimestamp = yesterday.timeIntervalSince1970
        
        var history = getDailyHistory()
        
        // Check if yesterday was missed and we have freezes
        let lastPlayDate = defaults.double(forKey: Keys.lastDailyPlayDate)
        let lastPlayDay = Date(timeIntervalSince1970: lastPlayDate)
        let lastPlayDayStart = Calendar.current.startOfDay(for: lastPlayDay)
        
        let daysSinceLastPlay = Calendar.current.dateComponents([.day], from: lastPlayDayStart, to: today).day ?? 0
        
        // If exactly 1 day was missed and we have freezes
        if daysSinceLastPlay == 2 && streakFreezeCount > 0 {
            // Check if yesterday doesn't already have a status
            if history[yesterdayTimestamp] == nil || history[yesterdayTimestamp] == .missed {
                // Use freeze
                history[yesterdayTimestamp] = .frozen
                saveDailyHistory(history)
                
                streakFreezeCount -= 1
                defaults.set(streakFreezeCount, forKey: Keys.streakFreezeCount)
            }
        }
        
        // Clean up old history (keep only last 30 days)
        cleanupOldHistory()
    }
    
    /// Get the last 5 days status for display
    func getLast5DaysStatus() -> [(date: Date, status: DayStatus)] {
        let today = Calendar.current.startOfDay(for: Date())
        let history = getDailyHistory()
        
        var result: [(Date, DayStatus)] = []
        
        for i in (0..<5).reversed() {
            guard let date = Calendar.current.date(byAdding: .day, value: -i, to: today) else { continue }
            let timestamp = date.timeIntervalSince1970
            
            if i == 0 {
                // Today
                if let status = history[timestamp], status == .completed {
                    result.append((date, .completed))
                } else {
                    result.append((date, .today))
                }
            } else {
                // Past days
                if let status = history[timestamp] {
                    result.append((date, status))
                } else {
                    result.append((date, .missed))
                }
            }
        }
        
        return result
    }
    
    /// Get current daily streak
    func getDailyStreak() -> Int {
        // First check if streak should be reset
        let today = Calendar.current.startOfDay(for: Date())
        let lastPlayDate = defaults.double(forKey: Keys.lastDailyPlayDate)
        
        if lastPlayDate == 0 {
            return 0
        }
        
        let lastPlayDay = Date(timeIntervalSince1970: lastPlayDate)
        let lastPlayDayStart = Calendar.current.startOfDay(for: lastPlayDay)
        
        let daysDifference = Calendar.current.dateComponents([.day], from: lastPlayDayStart, to: today).day ?? 0
        
        // Check if freeze was used for yesterday
        if daysDifference == 2 {
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            let history = getDailyHistory()
            if history[yesterday.timeIntervalSince1970] == .frozen {
                return defaults.integer(forKey: Keys.currentDailyStreak)
            }
        }
        
        if daysDifference > 1 {
            // Streak is broken
            defaults.set(0, forKey: Keys.currentDailyStreak)
            return 0
        }
        
        return defaults.integer(forKey: Keys.currentDailyStreak)
    }
    
    /// Get longest daily streak
    func getLongestDailyStreak() -> Int {
        return defaults.integer(forKey: Keys.longestDailyStreak)
    }
    
    /// Get current freeze count
    func getFreezeCount() -> Int {
        return min(defaults.integer(forKey: Keys.streakFreezeCount), Self.maxFreezes)
    }
    
    /// Get total days completed
    func getTotalDaysCompleted() -> Int {
        return defaults.integer(forKey: Keys.totalDaysCompleted)
    }
    
    // MARK: - Freeze System
    
    private func checkAndAwardFreeze(totalDays: Int) {
        let lastAwardedAt = defaults.integer(forKey: Keys.lastFreezeAwardedAt)
        let currentFreezes = defaults.integer(forKey: Keys.streakFreezeCount)
        
        // Check if we've crossed a 30-day milestone
        let newMilestone = (totalDays / Self.daysPerFreeze) * Self.daysPerFreeze
        let oldMilestone = (lastAwardedAt / Self.daysPerFreeze) * Self.daysPerFreeze
        
        if newMilestone > oldMilestone && currentFreezes < Self.maxFreezes {
            // Award a freeze
            let newFreezeCount = min(currentFreezes + 1, Self.maxFreezes)
            defaults.set(newFreezeCount, forKey: Keys.streakFreezeCount)
            defaults.set(totalDays, forKey: Keys.lastFreezeAwardedAt)
            streakFreezeCount = newFreezeCount
        }
    }
    
    // MARK: - History Management
    
    private func getDailyHistory() -> [Double: DayStatus] {
        guard let data = defaults.data(forKey: Keys.dailyHistory),
              let history = try? JSONDecoder().decode([Double: DayStatus].self, from: data) else {
            return [:]
        }
        return history
    }
    
    private func saveDailyHistory(_ history: [Double: DayStatus]) {
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: Keys.dailyHistory)
        }
    }
    
    private func cleanupOldHistory() {
        var history = getDailyHistory()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!.timeIntervalSince1970
        
        history = history.filter { $0.key >= thirtyDaysAgo }
        saveDailyHistory(history)
    }
    
    // MARK: - Free Play Difficulty Streaks (kept for compatibility)
    
    func recordPlay(for difficulty: Difficulty) {
        let today = Calendar.current.startOfDay(for: Date())
        let todayTimestamp = today.timeIntervalSince1970
        
        let lastPlayDate = getLastPlayDate(for: difficulty)
        let lastPlayDay = Date(timeIntervalSince1970: lastPlayDate)
        let lastPlayDayStart = Calendar.current.startOfDay(for: lastPlayDay)
        
        let daysDifference = Calendar.current.dateComponents([.day], from: lastPlayDayStart, to: today).day ?? 0
        
        var currentStreak = getCurrentStreak(for: difficulty)
        
        if daysDifference == 0 {
            if currentStreak == 0 {
                currentStreak = 1
            }
        } else if daysDifference == 1 {
            currentStreak += 1
        } else {
            currentStreak = 1
        }
        
        setLastPlayDate(todayTimestamp, for: difficulty)
        setCurrentStreak(currentStreak, for: difficulty)
        
        let longestStreak = getLongestStreak(for: difficulty)
        if currentStreak > longestStreak {
            setLongestStreak(currentStreak, for: difficulty)
        }
    }
    
    func getCurrentStreak(for difficulty: Difficulty) -> Int {
        return defaults.integer(forKey: Keys.currentStreak(difficulty))
    }
    
    func getLongestStreak(for difficulty: Difficulty) -> Int {
        return defaults.integer(forKey: Keys.longestStreak(difficulty))
    }
    
    func checkStreakStatus(for difficulty: Difficulty) -> StreakStatus {
        let lastPlayDate = getLastPlayDate(for: difficulty)
        
        if lastPlayDate == 0 {
            return .broken
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastPlayDay = Date(timeIntervalSince1970: lastPlayDate)
        let lastPlayDayStart = Calendar.current.startOfDay(for: lastPlayDay)
        
        let daysDifference = Calendar.current.dateComponents([.day], from: lastPlayDayStart, to: today).day ?? 0
        
        if daysDifference == 0 {
            return .active
        } else if daysDifference == 1 {
            return .atRisk
        } else {
            return .broken
        }
    }
    
    // MARK: - Average Time Tracking
    
    func recordTime(_ time: TimeInterval, for difficulty: Difficulty) {
        let totalTime = defaults.double(forKey: Keys.totalTime(difficulty)) + time
        defaults.set(totalTime, forKey: Keys.totalTime(difficulty))
    }
    
    func getAverageTime(for difficulty: Difficulty) -> TimeInterval {
        let solveCountKey = "solveCount_\(difficulty.rawValue)"
        let solveCount = defaults.integer(forKey: solveCountKey)
        let totalTime = defaults.double(forKey: Keys.totalTime(difficulty))
        
        if solveCount == 0 {
            return 0
        }
        
        return totalTime / Double(solveCount)
    }
    
    // MARK: - Private Helpers
    
    private func getLastPlayDate(for difficulty: Difficulty) -> Double {
        return defaults.double(forKey: Keys.lastPlayDate(difficulty))
    }
    
    private func setLastPlayDate(_ date: Double, for difficulty: Difficulty) {
        defaults.set(date, forKey: Keys.lastPlayDate(difficulty))
    }
    
    private func setCurrentStreak(_ streak: Int, for difficulty: Difficulty) {
        defaults.set(streak, forKey: Keys.currentStreak(difficulty))
    }
    
    private func setLongestStreak(_ streak: Int, for difficulty: Difficulty) {
        defaults.set(streak, forKey: Keys.longestStreak(difficulty))
    }
}

// Keep old StreakStatus for compatibility
enum StreakStatus {
    case active
    case atRisk
    case broken
}
