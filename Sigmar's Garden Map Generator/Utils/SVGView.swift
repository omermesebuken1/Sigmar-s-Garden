//
//  SVGView.swift
//  Sigmar's Garden Map Generator
//
//  Created on iOS
//

import SwiftUI
import WebKit
import UIKit

// Cache for SVG content and HTML
class SVGCache {
    static let shared = SVGCache()
    private var svgContentCache: [String: String] = [:]
    private var htmlCache: [String: String] = [:]
    
    private init() {}
    
    func getSVGContent(name: String) -> String? {
        if let cached = svgContentCache[name] {
            return cached
        }
        
        var url: URL?
        url = Bundle.main.url(forResource: name, withExtension: "svg", subdirectory: "Assets/Icons")
        
        if url == nil {
            url = Bundle.main.url(forResource: name, withExtension: "svg")
        }
        
        if url == nil, let bundlePath = Bundle.main.resourcePath {
            let fullPath = "\(bundlePath)/Assets/Icons/\(name).svg"
            url = URL(fileURLWithPath: fullPath)
        }
        
        guard let fileURL = url,
              let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
            return nil
        }
        
        svgContentCache[name] = content
        return content
    }
    
    func getHTML(svgName: String, colorHex: String) -> String {
        let cacheKey = "\(svgName)_\(colorHex)"
        
        if let cached = htmlCache[cacheKey] {
            return cached
        }
        
        guard let svgContent = getSVGContent(name: svgName) else {
            return ""
        }
        
        let modifiedSVG = svgContent.replacingOccurrences(
            of: "fill: #1d1d1b",
            with: "fill: \(colorHex)"
        )
        
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 0;
                    background: transparent;
                }
                svg {
                    width: 100%;
                    height: 100%;
                }
            </style>
        </head>
        <body>
            \(modifiedSVG)
        </body>
        </html>
        """
        
        htmlCache[cacheKey] = html
        return html
    }
}

struct SVGView: UIViewRepresentable {
    let svgName: String
    let iconColor: Color
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let colorHex = iconColor.toHex()
        let html = SVGCache.shared.getHTML(svgName: svgName, colorHex: colorHex)
        
        guard !html.isEmpty else {
            return
        }
        
        // Only reload if content changed
        webView.loadHTMLString(html, baseURL: nil)
    }
}

extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255) << 0
        
        return String(format: "#%06x", rgb)
    }
}

