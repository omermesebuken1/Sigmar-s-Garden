//
//  RulesView.swift
//  Sigmar's Garden Map Generator
//

import SwiftUI

struct RulesView: View {
    var body: some View {
        NavigationStack {
            List {
                // Goal
                Section("Goal") {
                    Label("Clear all marbles from the board", systemImage: "target")
                }
                
                // Free Marbles
                Section {
                    Text("A marble is **free** if it has 3 contiguous empty spaces around it.")
                    Text("Only free marbles can be selected.")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Unlocking Marbles")
                }
                
                // Cardinal Elements
                Section {
                    HStack(spacing: 12) {
                        ElementIcon("FireIcon", color: .red)
                        ElementIcon("WaterIcon", color: .blue)
                        ElementIcon("AirIcon", color: .cyan)
                        ElementIcon("EarthIcon", color: .green)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    
                    Text("Match two of the **same** element to remove them.")
                } header: {
                    Text("Cardinal Elements")
                }
                
                // Salt
                Section {
                    HStack(spacing: 12) {
                        ElementIcon("SaltIcon", color: .gray)
                        Text("+")
                            .foregroundStyle(.secondary)
                        ElementIcon("FireIcon", color: .red)
                        Text("or")
                            .foregroundStyle(.secondary)
                        ElementIcon("WaterIcon", color: .blue)
                        Text("...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    
                    Text("Salt matches with **any cardinal element** or another Salt.")
                } header: {
                    Text("Salt")
                }
                
                // Life & Death
                Section {
                    HStack(spacing: 12) {
                        ElementIcon("LifeIcon", color: .green)
                        Text("+")
                            .foregroundStyle(.secondary)
                        ElementIcon("DeathIcon", color: .purple)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    
                    Text("Vitae and Mors only match **with each other**.")
                } header: {
                    Text("Life & Death")
                }
                
                // Metals
                Section {
                    HStack(spacing: 8) {
                        ElementIcon("QuicksilverIcon", color: .gray)
                        Text("+")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ElementIcon("LeadIcon", color: .gray)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ElementIcon("TinIcon", color: .gray)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ElementIcon("IronIcon", color: .gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ElementIcon("CopperIcon", color: .orange)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ElementIcon("SilverIcon", color: .gray)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ElementIcon("GoldIcon", color: .yellow)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                    
                    Text("Use **Quicksilver** to remove metals in order.")
                } header: {
                    Text("Metal Transmutation")
                }
                
                // Gold
                Section {
                    HStack {
                        ElementIcon("GoldIcon", color: .yellow)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    
                    Text("Gold can be removed **alone** (single tap).")
                    Text("Must be the **last piece** on the board.")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Gold")
                }
            }
            .navigationTitle("Rules")
        }
    }
}

struct ElementIcon: View {
    let name: String
    let color: Color
    
    init(_ name: String, color: Color) {
        self.name = name
        self.color = color
    }
    
    var body: some View {
        Image(name)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 32, height: 32)
            .padding(6)
            .background(color.opacity(0.2), in: Circle())
    }
}

#Preview {
    RulesView()
}
