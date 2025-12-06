//
//  HexagonView.swift
//  SigmarGarden
//
//  Created on iOS
//

import SwiftUI

struct HexagonView: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Pointy-top hexagon (yatay uzun)
        let centerX = width / 2
        let centerY = height / 2
        let radius = min(width, height) / 2
        
        for i in 0..<6 {
            // Pointy-top: başlangıç açısı 0 (üst noktadan başla)
            let angle = Double.pi / 3.0 * Double(i)
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.closeSubpath()
        return path
    }
}

struct HexagonShape: View {
    var body: some View {
        HexagonView()
            .fill(Color.gray.opacity(0.3))
            .stroke(Color.white, lineWidth: 1)
    }
}
