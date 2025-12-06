//
//  Sigmar_s_Garden_Map_GeneratorApp.swift
//  Sigmar's Garden Map Generator
//
//  Created by Ömer Faruk Meşebüken on 5.12.2025.
//

import SwiftUI

@main
struct Sigmar_s_Garden_Map_GeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                Tab("Ranks", systemImage: "chart.bar.fill") {
                    LeaderboardsView()
                }
                
                Tab("Play", systemImage: "hexagon.fill") {
                    ContentView()
                }
                
                Tab("Rules", systemImage: "book.fill") {
                    RulesView()
                }
            }
        }
    }
}
