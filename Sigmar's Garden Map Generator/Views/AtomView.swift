//
//  AtomView.swift
//  SigmarGarden
//
//  Created on iOS
//

import SwiftUI

struct AtomView: View {
    let atomType: String
    let isSelectable: Bool
    let isSelected: Bool
    let hexWidth: CGFloat
    let hexHeight: CGFloat
    
    var body: some View {
        ZStack {
            // Background hexagon filled with color
            HexagonView()
                .fill(backgroundColor)
                .overlay(
                    HexagonView()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .overlay(
                    HexagonView()
                        .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
                )
                .opacity(isSelectable ? 1.0 : 0.3)
            
            // SVG Icon from Asset Catalog (template rendering for color)
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(iconColor)
                .frame(width: hexWidth * 0.55, height: hexHeight * 0.55)
                .opacity(isSelectable ? 1.0 : 0.3)
        }
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
        case "salt": return .black
        case "quintessence": return .white
        case "quicksilver": return .black
        case "lead": return .white
        case "tin": return .cyan
        case "iron": return .red
        case "copper": return .orange
        case "silver": return .gray
        case "gold": return .yellow
        case "mors": return .red
        case "vitae": return .green
        default: return .black
        }
    }
    
}

