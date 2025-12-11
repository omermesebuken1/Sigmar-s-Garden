//
//  TutorialView.swift
//  Sigmar's Garden Map Generator
//
//  Interactive tutorial for first-time players
//

import SwiftUI

struct TutorialView: View {
    @Binding var tutorialCompleted: Bool
    
    @State private var currentStep: TutorialStep = .welcome
    @State private var cells: [Cell] = []
    @State private var selectedCells: Set<Int> = []
    @State private var showShakeAnimation = false
    @State private var highlightedCellIds: Set<Int> = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: currentStep.progress)
                        .tint(.green)
                        .padding(.horizontal, 40)
                        .padding(.top, 16)
                    
                    // Step indicator
                    Text("Step \(currentStep.rawValue + 1) of \(TutorialStep.allCases.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    
                    // Instruction card
                    VStack(spacing: 12) {
                        Text(currentStep.title)
                            .font(.title2.bold())
                        
                        Text(currentStep.instruction)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // Tutorial board
                    if !cells.isEmpty {
                        TutorialBoardView(
                            cells: cells,
                            selectedCells: selectedCells,
                            highlightedCellIds: highlightedCellIds,
                            currentStep: currentStep,
                            onCellTapped: handleCellTap,
                            availableSize: CGSize(
                                width: geometry.size.width,
                                height: geometry.size.height * 0.45
                            )
                        )
                        .modifier(ShakeEffect(shakes: showShakeAnimation ? 2 : 0))
                    }
                    
                    Spacer()
                    
                    // Bottom buttons
                    HStack(spacing: 20) {
                        if !currentStep.isInteractive || currentStep == .complete {
                            Button {
                                advanceToNextStep()
                            } label: {
                                Text(currentStep == .complete ? "Start Playing!" : "Next")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(currentStep == .complete ? .green : .blue)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            setupTutorial()
        }
    }
    
    // MARK: - Setup
    
    private func setupTutorial() {
        cells = TutorialBoardGenerator.generateTutorialBoard()
        TutorialBoardGenerator.updateSelectability(&cells)
        updateHighlightedCells()
    }
    
    // MARK: - Highlighting
    
    private func updateHighlightedCells() {
        highlightedCellIds = []
        
        let requiredAtoms = currentStep.requiredAtoms
        guard !requiredAtoms.isEmpty else { return }
        
        // Find cells containing required atoms
        for cell in cells {
            if requiredAtoms.contains(cell.contains) && cell.selectable {
                highlightedCellIds.insert(cell.id)
            }
        }
    }
    
    // MARK: - Cell Tap Handling
    
    private func handleCellTap(_ cellId: Int) {
        guard currentStep.isInteractive else { return }
        
        guard let cellIndex = cells.firstIndex(where: { $0.id == cellId }),
              cells[cellIndex].selectable else { return }
        
        let tappedAtom = cells[cellIndex].contains
        
        // Check if this is a valid tap for current step
        if !isValidTapForStep(atom: tappedAtom, cellId: cellId) {
            triggerShake()
            return
        }
        
        // Handle selection
        if selectedCells.contains(cellId) {
            selectedCells.remove(cellId)
        } else {
            selectedCells.insert(cellId)
        }
        
        // Check for match completion
        checkForMatchCompletion()
    }
    
    private func isValidTapForStep(atom: String, cellId: Int) -> Bool {
        let requiredAtoms = currentStep.requiredAtoms
        
        // For gold step, only gold is valid
        if currentStep == .gold {
            return atom == "gold"
        }
        
        // Check if atom is in required list
        return requiredAtoms.contains(atom)
    }
    
    private func checkForMatchCompletion() {
        let requiredAtoms = currentStep.requiredAtoms
        
        // Gold is special - single tap
        if currentStep == .gold && selectedCells.count == 1 {
            let selectedAtom = cells.first(where: { $0.id == Array(selectedCells)[0] })?.contains ?? ""
            if selectedAtom == "gold" {
                removeSelectedCells()
                advanceToNextStep()
                return
            }
        }
        
        // For pair matches
        if selectedCells.count == 2 {
            let selectedAtoms = selectedCells.compactMap { id -> String? in
                guard let index = cells.firstIndex(where: { $0.id == id }) else { return nil }
                return cells[index].contains
            }
            
            // Check if this is the correct match for current step
            if Set(selectedAtoms) == Set(requiredAtoms) || 
               (selectedAtoms[0] == selectedAtoms[1] && requiredAtoms[0] == requiredAtoms[1]) {
                removeSelectedCells()
                advanceToNextStep()
            } else {
                selectedCells.removeAll()
            }
        }
    }
    
    private func removeSelectedCells() {
        for id in selectedCells {
            if let index = cells.firstIndex(where: { $0.id == id }) {
                cells[index].contains = ""
            }
        }
        selectedCells.removeAll()
        TutorialBoardGenerator.updateSelectability(&cells)
    }
    
    private func triggerShake() {
        withAnimation(.default) {
            showShakeAnimation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showShakeAnimation = false
        }
    }
    
    // MARK: - Step Navigation
    
    private func advanceToNextStep() {
        if currentStep == .complete {
            tutorialCompleted = true
            return
        }
        
        if let nextStep = currentStep.nextStep {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = nextStep
            }
            selectedCells.removeAll()
            updateHighlightedCells()
        }
    }
}

// MARK: - Tutorial Board View

struct TutorialBoardView: View {
    let cells: [Cell]
    let selectedCells: Set<Int>
    let highlightedCellIds: Set<Int>
    let currentStep: TutorialStep
    let onCellTapped: (Int) -> Void
    let availableSize: CGSize
    
    private let gridSize = 7
    
    private var hexHeight: CGFloat {
        let size = availableSize.height / 8
        return max(40, min(size, 55))
    }
    
    private var hexWidth: CGFloat {
        return hexHeight * 1.15
    }
    
    private var centerX: Int { gridSize / 2 }
    private var centerY: Int { gridSize / 2 }
    
    var body: some View {
        GeometryReader { geometry in
            let screenCenterX = geometry.size.width / 2
            let screenCenterY = geometry.size.height / 2
            
            ZStack {
                ForEach(cells.filter { $0.rendered }) { cell in
                    let isHighlighted = highlightedCellIds.contains(cell.id)
                    let shouldDim = currentStep.isInteractive && !highlightedCellIds.isEmpty && !isHighlighted && !cell.contains.isEmpty
                    
                    ZStack {
                        HexTileView(
                            atomType: cell.contains.isEmpty ? nil : cell.contains,
                            isSelectable: cell.selectable,
                            isSelected: selectedCells.contains(cell.id),
                            isGameActive: true,
                            hexWidth: hexWidth,
                            hexHeight: hexHeight
                        )
                        .opacity(shouldDim ? 0.3 : 1.0)
                        
                        // Pulse animation for highlighted cells
                        if isHighlighted {
                            HexagonView()
                                .stroke(Color.yellow, lineWidth: 3)
                                .frame(width: hexWidth, height: hexHeight)
                                .modifier(PulseEffect())
                        }
                    }
                    .position(position(for: cell, screenCenter: CGPoint(x: screenCenterX, y: screenCenterY)))
                    .onTapGesture {
                        if !cell.contains.isEmpty && cell.contains != "ph" {
                            onCellTapped(cell.id)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
    
    private func columnCenterRow(for y: Int) -> Double {
        let halfGrid = gridSize / 2
        let minX = max(0, halfGrid - y)
        let maxX = min(gridSize - 1, gridSize + halfGrid - 1 - y)
        return Double(minX + maxX) / 2.0
    }
    
    private func position(for cell: Cell, screenCenter: CGPoint) -> CGPoint {
        let col = cell.y - centerY
        
        let colSpacing = hexWidth * 0.76
        let rowSpacing = hexHeight * 0.97
        
        let x = screenCenter.x + CGFloat(col) * colSpacing
        
        let columnCenter = columnCenterRow(for: cell.y)
        let rowOffset = Double(cell.x) - columnCenter
        let y = screenCenter.y + CGFloat(rowOffset) * rowSpacing
        
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
    var shakes: Int
    var animatableData: CGFloat {
        get { CGFloat(shakes) }
        set { shakes = Int(newValue) }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(animatableData * .pi * 4) * 10
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

// MARK: - Pulse Effect

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

#Preview {
    TutorialView(tutorialCompleted: .constant(false))
}

