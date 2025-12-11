//
//  TutorialStep.swift
//  Sigmar's Garden Map Generator
//
//  Tutorial step definitions
//

import Foundation

enum TutorialStep: Int, CaseIterable {
    case welcome = 0
    case freeMarble = 1
    case cardinalElements = 2
    case salt = 3
    case morsVitae = 4
    case metals = 5
    case gold = 6
    case complete = 7
    
    var title: String {
        switch self {
        case .welcome: return "Welcome!"
        case .freeMarble: return "Free Marbles"
        case .cardinalElements: return "Elements"
        case .salt: return "Salt"
        case .morsVitae: return "Life & Death"
        case .metals: return "Metals"
        case .gold: return "Gold"
        case .complete: return "Ready!"
        }
    }
    
    var instruction: String {
        switch self {
        case .welcome:
            return "Clear all marbles from the board by matching pairs. Tap 'Next' to learn how!"
        case .freeMarble:
            return "A marble is free when it has 3 consecutive empty spaces around it. Only free marbles can be selected."
        case .cardinalElements:
            return "Match two of the same element to remove them. Tap both Fire marbles."
        case .salt:
            return "Salt matches with any cardinal element. Match the Salt with Water."
        case .morsVitae:
            return "Mors (Death) and Vitae (Life) only match with each other. Match them now."
        case .metals:
            return "Use Quicksilver to remove metals in order: Lead → Tin → Iron → Copper → Silver. Match Quicksilver with Lead."
        case .gold:
            return "Gold can be removed alone with a single tap when it's free. Tap the Gold!"
        case .complete:
            return "Excellent! You've learned all the rules. You're ready to play!"
        }
    }
    
    var requiredAtoms: [String] {
        switch self {
        case .welcome: return []
        case .freeMarble: return []
        case .cardinalElements: return ["fire", "fire"]
        case .salt: return ["salt", "water"]
        case .morsVitae: return ["mors", "vitae"]
        case .metals: return ["quicksilver", "lead"]
        case .gold: return ["gold"]
        case .complete: return []
        }
    }
    
    var isInteractive: Bool {
        switch self {
        case .welcome, .freeMarble, .complete:
            return false
        default:
            return true
        }
    }
    
    var nextStep: TutorialStep? {
        let allCases = TutorialStep.allCases
        guard let currentIndex = allCases.firstIndex(of: self),
              currentIndex + 1 < allCases.count else {
            return nil
        }
        return allCases[currentIndex + 1]
    }
    
    var progress: Double {
        return Double(self.rawValue) / Double(TutorialStep.allCases.count - 1)
    }
}

