//
//  ColorScheme.swift
//  TaskVantage Road
//
//  Created by Developer on 1/9/25.
//

import SwiftUI

struct AppColorScheme {
    // Primary Colors as specified
    static let background = Color(hex: "#3e4464")
    static let primaryAction = Color(hex: "#fcc418")
    static let secondaryAction = Color(hex: "#3cc45b")
    
    // Complementary Colors
    static let cardBackground = Color(hex: "#4a5078")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#b8bcc8")
    static let textTertiary = Color(hex: "#9ca3af")
    
    // Status Colors
    static let success = Color(hex: "#10b981")
    static let warning = Color(hex: "#f59e0b")
    static let error = Color(hex: "#ef4444")
    static let info = Color(hex: "#3b82f6")
    
    // Neumorphism Colors
    static let shadowDark = Color(hex: "#2a2f47")
    static let shadowLight = Color(hex: "#525881")
    
    // Gradient Colors
    static let gradientStart = Color(hex: "#434a6b")
    static let gradientEnd = Color(hex: "#363c5d")
    
    // Priority Colors (matching TaskPriority enum)
    static let priorityLow = Color(hex: "#22c55e")
    static let priorityMedium = Color(hex: "#eab308")
    static let priorityHigh = Color(hex: "#f97316")
    static let priorityCritical = Color(hex: "#ef4444")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// MARK: - Theme Protocol
protocol Theme {
    var backgroundColor: Color { get }
    var primaryColor: Color { get }
    var secondaryColor: Color { get }
    var textColor: Color { get }
    var cardColor: Color { get }
}

struct DefaultTheme: Theme {
    let backgroundColor = AppColorScheme.background
    let primaryColor = AppColorScheme.primaryAction
    let secondaryColor = AppColorScheme.secondaryAction
    let textColor = AppColorScheme.textPrimary
    let cardColor = AppColorScheme.cardBackground
}

