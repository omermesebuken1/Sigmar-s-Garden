//
//  HexTileView.swift
//  Sigmar's Garden
//
//  Unified hex tile component
//

import SwiftUI

struct HexTileView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let atomType: String?  // nil for empty tile
    let isSelectable: Bool
    let isSelected: Bool
    let hexWidth: CGFloat
    let hexHeight: CGFloat
    
    var body: some View {
        ZStack {
            // Fill (affected by selectability)
            HexagonView()
                .fill(fillColor)
                .opacity(contentOpacity)
            
            // Stroke - ALWAYS visible, not affected by selectability
            HexagonView()
                .stroke(strokeColor, lineWidth: strokeWidth)
            
            // Selection highlight
            if isSelected {
                HexagonView()
                    .stroke(Color.yellow, lineWidth: 3)
            }
            
            // Icon (only for filled tiles, affected by selectability)
            if let atomType = atomType, !atomType.isEmpty, atomType != "ph" {
                Image(iconName(for: atomType))
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(iconColor(for: atomType))
                    .frame(width: hexWidth * 0.55, height: hexHeight * 0.55)
                    .opacity(contentOpacity)
            }
        }
        .frame(width: hexWidth, height: hexHeight)
    }
    
    // MARK: - Computed Properties
    
    private var contentOpacity: Double {
        isSelectable ? 1.0 : 0.3
    }
    
    private var strokeColor: Color {
        colorScheme == .light ? Color.black.opacity(0.3) : Color.white.opacity(0.3)
    }
    
    private var strokeWidth: CGFloat {
        1.5
    }
    
    private var fillColor: Color {
        guard let atomType = atomType, !atomType.isEmpty, atomType != "ph" else {
            // Empty tile
            return colorScheme == .light ? Color.gray.opacity(0.15) : Color.white.opacity(0.1)
        }
        return backgroundColor(for: atomType)
    }
    
    // MARK: - Atom Properties
    
    private func iconName(for atomType: String) -> String {
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
    
    private func backgroundColor(for atomType: String) -> Color {
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
    
    private func iconColor(for atomType: String) -> Color {
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

