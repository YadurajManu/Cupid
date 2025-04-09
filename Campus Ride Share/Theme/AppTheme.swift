//  AppTheme.swift
//  Cupid
//
//  Created by Yaduraj Singh on 09/04/25.
//

import SwiftUI

// MARK: - Colors
struct AppColors {
    static let background = Color.black
    static let primary = Color.white
    static let secondary = Color.gray
    static let accent = Color(hex: "F2F2F2") // Slightly off-white for subtle contrast
    
    static let textPrimary = Color.white
    static let textSecondary = Color.gray
    static let textDisabled = Color(white: 0.5)
    
    static let buttonBackground = Color.white
    static let buttonText = Color.black
    
    static let inputBackground = Color(white: 0.1)
    static let inputBorder = Color(white: 0.3)
    
    static let error = Color(hex: "FF4444")
    static let success = Color(hex: "AAAAAA") // Light gray for success in B&W theme
}

// MARK: - Typography
struct AppFonts {
    // Display
    static let displayLarge = Font.custom("Futura-Bold", size: 42)
    static let displayMedium = Font.custom("Futura-Medium", size: 36)
    static let displaySmall = Font.custom("Futura-Medium", size: 30)
    
    // Headlines
    static let headlineLarge = Font.custom("Futura-Medium", size: 28)
    static let headlineMedium = Font.custom("Futura-Medium", size: 24)
    static let headlineSmall = Font.custom("Futura-Medium", size: 20)
    
    // Body
    static let bodyLarge = Font.custom("Futura-Medium", size: 18)
    static let bodyMedium = Font.custom("Futura-Light", size: 16)
    static let bodySmall = Font.custom("Futura-Light", size: 14)
    
    // Labels
    static let labelLarge = Font.custom("Futura-Medium", size: 16)
    static let labelMedium = Font.custom("Futura-Medium", size: 14)
    static let labelSmall = Font.custom("Futura-Light", size: 12)
}

// MARK: - Spacing
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Border Radius
struct AppRadius {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let large: CGFloat = 16
    static let pill: CGFloat = 30
}

// MARK: - Animations
struct AppAnimations {
    static let standard = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.bodyLarge)
            .foregroundColor(AppColors.buttonText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.buttonBackground)
            .cornerRadius(AppRadius.pill)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppAnimations.standard, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFonts.bodyLarge)
            .foregroundColor(AppColors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.pill)
                    .stroke(AppColors.primary, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppAnimations.standard, value: configuration.isPressed)
    }
}

// MARK: - Extension for Hex Colors
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}