//
//  MatchingRules.swift
//  SigmarGarden
//
//  Created on iOS
//

import Foundation

struct MatchingRules {
    static func materialType(_ atom: String) -> MaterialType {
        if ["water", "fire", "air", "earth", "salt", "quintessence"].contains(atom) {
            return .cardinal
        } else if atom == "mors" || atom == "vitae" {
            return .mv
        } else {
            return .metal
        }
    }
    
    static func canMatch(_ atom1: String, _ atom2: String) -> Bool {
        let type1 = materialType(atom1)
        let type2 = materialType(atom2)
        
        // Cardinal elements match with same type or with salt
        if type1 == .cardinal && type2 == .cardinal {
            if atom1 == atom2 {
                return true
            }
            if atom1 == "salt" || atom2 == "salt" {
                return true
            }
            return false
        }
        
        // Mors and Vitae only match with their opposite
        if type1 == .mv && type2 == .mv {
            return atom1 != atom2
        }
        
        // Metals match with quicksilver (any metal can match with quicksilver)
        // But selectability is controlled by updateCellSelectability - only the first available metal is selectable
        if type1 == .metal && type2 == .metal {
            // Quicksilver matches with any metal (selectability ensures only correct metal is available)
            if atom1 == "quicksilver" || atom2 == "quicksilver" {
                return true
            }
            // Metals can match with each other in transmutation order (lead+tin, tin+iron, etc.)
            // But this is controlled by selectability - previous metal must be removed first
            let metals = AtomType.metals
            if let index1 = metals.firstIndex(of: atom1),
               let index2 = metals.firstIndex(of: atom2) {
                return abs(index1 - index2) == 1
            }
        }
        
        return false
    }
}

