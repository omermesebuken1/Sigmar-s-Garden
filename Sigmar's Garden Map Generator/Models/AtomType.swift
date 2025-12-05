//
//  AtomType.swift
//  SigmarGarden
//
//  Created on iOS
//

import Foundation

enum AtomType: String, CaseIterable {
    case water = "water"
    case fire = "fire"
    case air = "air"
    case earth = "earth"
    case salt = "salt"
    case quintessence = "quintessence"
    case quicksilver = "quicksilver"
    case lead = "lead"
    case tin = "tin"
    case iron = "iron"
    case copper = "copper"
    case silver = "silver"
    case gold = "gold"
    case mors = "mors"
    case vitae = "vitae"
    
    static let names = ["water", "fire", "air", "earth", "salt", "quintessence", "quicksilver", "lead", "tin", "iron", "copper", "silver", "gold", "mors", "vitae"]
    
    static let metals = ["lead", "tin", "iron", "copper", "silver", "gold"]
    
    var index: Int {
        return AtomType.names.firstIndex(of: self.rawValue) ?? 0
    }
    
    static func fromIndex(_ index: Int) -> AtomType? {
        guard index >= 0 && index < names.count else { return nil }
        return AtomType(rawValue: names[index])
    }
    
    func materialType() -> MaterialType {
        if ["water", "fire", "air", "earth", "salt", "quintessence"].contains(self.rawValue) {
            return .cardinal
        } else if self == .mors || self == .vitae {
            return .mv
        } else {
            return .metal
        }
    }
}

enum MaterialType {
    case cardinal
    case metal
    case mv
}

