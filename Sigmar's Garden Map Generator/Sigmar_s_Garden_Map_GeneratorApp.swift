//
//  Sigmar_s_Garden_Map_GeneratorApp.swift
//  Sigmar's Garden Map Generator
//
//  Created by Ömer Faruk Meşebüken on 5.12.2025.
//

import SwiftUI

@main
struct Sigmar_s_Garden_Map_GeneratorApp: App {
    @State private var selectedTab = "play"
    @AppStorage("tutorialCompleted") private var tutorialCompleted: Bool = false
    
    var body: some Scene {
        WindowGroup {
            if !tutorialCompleted {
                // Show tutorial for first-time users
                TutorialView(tutorialCompleted: $tutorialCompleted)
            } else {
                // Normal app with tabs
                TabView(selection: $selectedTab) {
                    Tab("Daily", systemImage: "calendar", value: "daily") {
                        DailyChallengeView()
                    }
                    
                    Tab("Play", systemImage: "hexagon.fill", value: "play") {
                        ContentView()
                    }
                    
                    Tab("Stats", systemImage: "chart.bar.fill", value: "stats") {
                        StatsView()
                    }
                    
                    Tab("Rules", systemImage: "book.fill", value: "rules") {
                        RulesView()
                    }
                }
                .tint(.green)
            }
        }
    }
}
