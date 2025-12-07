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
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                Tab("Ranks", systemImage: "chart.bar.fill", value: "ranks") {
                    LeaderboardsView()
                }
                
                Tab("Play", systemImage: "hexagon.fill", value: "play") {
                    ContentView()
                }
                
                Tab("Rules", systemImage: "book.fill", value: "rules") {
                    RulesView()
                }
            }
        }
    }
}
