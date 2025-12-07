//
//  AtomCounterView.swift
//  Sigmar's Garden Map Generator
//
//  Shows remaining atom counts with imbalance warnings
//

import SwiftUI

struct AtomCounterView: View {
    let cells: [Cell]
    
    @Environment(\.colorScheme) var colorScheme
    
    // Count remaining atoms by type
    private var atomCounts: [String: Int] {
        var counts: [String: Int] = [:]
        for cell in cells {
            let atom = cell.contains
            if !atom.isEmpty && atom != "ph" {
                counts[atom, default: 0] += 1
            }
        }
        return counts
    }
    
    // Row 1: Cardinal elements + Mors/Vitae
    private let row1: [String] = [
        "water", "fire", "air", "earth", "salt", "quintessence", "mors", "vitae"
    ]
    
    // Row 2: Metals
    private let row2: [String] = [
        "quicksilver", "lead", "tin", "iron", "copper", "silver", "gold"
    ]
    
    var body: some View {
        VStack(spacing: 6) {
            // Row 1
            HStack(spacing: 6) {
                ForEach(row1, id: \.self) { atomType in
                    if let count = atomCounts[atomType], count > 0 {
                        AtomCountBadge(
                            atomType: atomType,
                            count: count,
                            isImbalanced: isImbalanced(atomType: atomType, count: count)
                        )
                    }
                }
            }
            
            // Row 2
            HStack(spacing: 6) {
                ForEach(row2, id: \.self) { atomType in
                    if let count = atomCounts[atomType], count > 0 {
                        AtomCountBadge(
                            atomType: atomType,
                            count: count,
                            isImbalanced: isImbalanced(atomType: atomType, count: count)
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 12)
    }
    
    // Check if atom count is imbalanced
    private func isImbalanced(atomType: String, count: Int) -> Bool {
        switch atomType {
        // Elements that match with themselves - need even count
        case "water", "fire", "air", "earth", "quintessence":
            return count % 2 != 0
            
        // Mors and Vitae must have equal counts
        case "mors":
            let vitaeCount = atomCounts["vitae"] ?? 0
            return count != vitaeCount
        case "vitae":
            let morsCount = atomCounts["mors"] ?? 0
            return count != morsCount
            
        // Quicksilver matches with metals - needs even count relative to metals
        case "salt":
            return count % 2 != 0
            
        // Salt is flexible (matches with any cardinal) - usually ok
        case "salt":
            return false
            
        // Gold is removed alone - always ok
        case "gold":
            return false
            
        // Other metals (lead, tin, iron, copper, silver) - complex matching
        // For now, just check if there's a pair issue
        default:
            return false
        }
    }
}

struct AtomCountBadge: View {
    let atomType: String     
    let count: Int
    let isImbalanced: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Image(iconName)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .foregroundColor(iconColor)
            
            Text("\(count)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isImbalanced ? .red : .primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(backgroundColor)
                .overlay(
                    Capsule()
                        .strokeBorder(isImbalanced ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1.5)
                )
        )
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
    
    private var iconColor: Color {
        switch atomType {
        case "water": return .blue
        case "fire": return .red
        case "air": return .cyan
        case "earth": return .green
        case "salt": return .blue
        case "quintessence": return .purple
        case "quicksilver": return .orange
        case "lead": return .white
        case "tin": return .cyan
        case "iron": return .red
        case "copper": return .orange
        case "silver": return .gray
        case "gold": return .yellow
        case "mors": return .purple
        case "vitae": return .white
        default: return .gray
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .light 
            ? Color.gray.opacity(0.15) 
            : Color.white.opacity(0.1)
    }
}

#Preview {
    AtomCounterView(cells: [])
        .background(Color.black)
}

