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
                        RulesTileIcon(atomType: "fire")
                        RulesTileIcon(atomType: "water")
                        RulesTileIcon(atomType: "air")
                        RulesTileIcon(atomType: "earth")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    
                    Text("Match two of the **same** element to remove them.")
                } header: {
                    Text("Cardinal Elements")
                }
                
                // Salt
                Section {
                    HStack(spacing: 8) {
                        RulesTileIcon(atomType: "salt")
                        Text("+")
                            .foregroundStyle(.secondary)
                        RulesTileIcon(atomType: "fire")
                        Text("or")
                            .foregroundStyle(.secondary)
                        RulesTileIcon(atomType: "water")
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
                        RulesTileIcon(atomType: "vitae")
                        Text("+")
                            .foregroundStyle(.secondary)
                        RulesTileIcon(atomType: "mors")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                    
                    Text("Vitae and Mors only match **with each other**.")
                } header: {
                    Text("Life & Death")
                }
                
                // Metals
                Section {
                    HStack(spacing: 6) {
                        RulesTileIcon(atomType: "quicksilver")
                        Text("+")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        RulesTileIcon(atomType: "lead")
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        RulesTileIcon(atomType: "tin")
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        RulesTileIcon(atomType: "iron")
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        RulesTileIcon(atomType: "copper")
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        RulesTileIcon(atomType: "silver")
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        RulesTileIcon(atomType: "gold")
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
                        RulesTileIcon(atomType: "gold")
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

// MARK: - Rules Tile Icon (matches game appearance)

struct RulesTileIcon: View {
    let atomType: String
    private let size: CGFloat = 36
    
    var body: some View {
        ZStack {
            // Hexagon background
            HexagonView()
                .fill(backgroundColor)
            
            // Hexagon stroke
            HexagonView()
                .stroke(Color.black.opacity(0.3), lineWidth: 1)
            
            // Icon
            Image(iconName)
                .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
                .foregroundColor(iconColor)
                .frame(width: size * 0.55, height: size * 0.55)
        }
        .frame(width: size, height: size)
    }
    
    private var iconName: String {
        switch atomType {
        case "water": return "WaterIcon"
        case "fire": return "FireIcon"
        case "air": return "AirIcon"
        case "earth": return "EarthIcon"
        case "salt": return "SaltIcon"
        case "quintessence": return "GoldIcon"
        case "quicksilver": return "QuicksilverIcon"
        case "lead": return "LeadIcon"
        case "tin": return "TinIcon"
        case "iron": return "IronIcon"
        case "copper": return "CopperIcon"
        case "silver": return "SilverIcon"
        case "gold": return "GoldIcon"
        case "mors": return "DeathIcon"
        case "vitae": return "LifeIcon"
        default: return "GoldIcon"
        }
    }
    
    private var backgroundColor: Color {
        switch atomType {
        case "water": return Color(red: 0.2, green: 0.4, blue: 0.9)
        case "fire": return Color(red: 0.9, green: 0.3, blue: 0.2)
        case "air": return Color(red: 0.7, green: 0.9, blue: 1.0)
        case "earth": return .green
        case "salt": return .white
        case "quintessence": return Color(red: 0.6, green: 0.3, blue: 0.8)
        case "quicksilver": return .white
        case "lead": return Color(red: 0.1, green: 0.1, blue: 0.1)
        case "tin": return Color(red: 0.1, green: 0.1, blue: 0.1)
        case "iron": return Color(red: 0.1, green: 0.1, blue: 0.1)
        case "copper": return Color(red: 0.1, green: 0.1, blue: 0.1)
        case "silver": return Color(red: 0.1, green: 0.1, blue: 0.1)
        case "gold": return Color(red: 0.1, green: 0.1, blue: 0.1)
        case "mors": return Color(red: 0.3, green: 0.2, blue: 0.2)
        case "vitae": return Color(red: 0.3, green: 0.2, blue: 0.2)
        default: return .gray
        }
    }
    
    private var iconColor: Color {
        switch atomType {
        case "water": return .white
        case "fire": return .white
        case "air": return .white
        case "earth": return .white
        case "salt": return .blue
        case "quintessence": return .white
        case "quicksilver": return .orange
        case "lead": return .white
        case "tin": return .cyan
        case "iron": return .red
        case "copper": return .orange
        case "silver": return .gray
        case "gold": return .yellow
        case "mors": return .purple
        case "vitae": return .white
        default: return .black
        }
    }
}

#Preview {
    RulesView()
}
