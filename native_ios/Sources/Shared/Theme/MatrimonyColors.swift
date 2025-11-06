#if os(iOS)
import SwiftUI

@available(iOS 17, *)
struct MatrimonyColors {
    // Primary Colors - Traditional Marriage Theme
    static let matrimonyPrimary = Color(red: 0.82, green: 0.18, blue: 0.18) // Deep Red/Maroon
    static let matrimonyPrimaryDark = Color(red: 0.62, green: 0.08, blue: 0.08) // Darker Red
    static let matrimonyPrimaryLight = Color(red: 0.92, green: 0.38, blue: 0.38) // Lighter Red
    
    // Secondary Colors - Gold/Accent
    static let matrimonySecondary = Color(red: 0.95, green: 0.78, blue: 0.35) // Gold
    static let matrimonySecondaryDark = Color(red: 0.85, green: 0.68, blue: 0.25) // Darker Gold
    static let matrimonySecondaryLight = Color(red: 1.0, green: 0.88, blue: 0.55) // Lighter Gold
    
    // Background Colors
    static let matrimonyBackground = Color(red: 0.98, green: 0.97, blue: 0.95) // Warm White
    static let matrimonyCardBackground = Color.white
    static let matrimonyGroupedBackground = Color(red: 0.95, green: 0.94, blue: 0.92) // Light Gray
    
    // Text Colors
    static let matrimonyText = Color(red: 0.2, green: 0.2, blue: 0.2) // Dark Gray
    static let matrimonyTextSecondary = Color(red: 0.4, green: 0.4, blue: 0.4) // Medium Gray
    static let matrimonyMuted = Color(red: 0.6, green: 0.6, blue: 0.6) // Light Gray
    
    // Status Colors
    static let matrimonySuccess = Color(red: 0.2, green: 0.7, blue: 0.2) // Green
    static let matrimonyWarning = Color(red: 0.9, green: 0.6, blue: 0.1) // Orange
    static let matrimonyError = Color(red: 0.8, green: 0.2, blue: 0.2) // Red
    
    // Special Colors for Matrimony Features
    static let matrimonySacred = Color(red: 0.6, green: 0.2, blue: 0.8) // Purple for sacred aspects
    static let matrimonyFamily = Color(red: 0.4, green: 0.6, blue: 0.8) // Blue for family
    static let matrimonyTradition = Color(red: 0.7, green: 0.4, blue: 0.2) // Brown for tradition
    
    // Gradient Definitions
    static let matrimonyPrimaryGradient = LinearGradient(
        colors: [matrimonyPrimary, matrimonyPrimaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let matrimonySecondaryGradient = LinearGradient(
        colors: [matrimonySecondary, matrimonySecondaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let matrimonyBackgroundGradient = LinearGradient(
        colors: [matrimonyBackground, matrimonyGroupedBackground],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let matrimonySacredGradient = LinearGradient(
        colors: [matrimonySacred, matrimonyPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Color Extensions

@available(iOS 17, *)
extension Color {
    // Matrimony-specific colors for easy access
    static let matrimonyRed = MatrimonyColors.matrimonyPrimary
    static let matrimonyGold = MatrimonyColors.matrimonySecondary
    static let matrimonyPurple = MatrimonyColors.matrimonySacred
    static let matrimonyBlue = MatrimonyColors.matrimonyFamily
    static let matrimonyBrown = MatrimonyColors.matrimonyTradition
}

// MARK: - Theme Configuration

@available(iOS 17, *)
struct MatrimonyTheme {
    static func configure() {
        // Configure any global theme settings here
        // This would be called at app startup
    }
    
    // Button Styles - TODO: Fix PrimitiveButtonStyle implementation
    // static let primaryButtonStyle = PrimitiveButtonStyle { configuration in
    //     configuration.label
    //         .font(.system(size: 16, weight: .semibold))
    //         .foregroundStyle(.white)
    //         .frame(maxWidth: .infinity)
    //         .padding(.vertical, 16)
    //         .background(MatrimonyColors.matrimonyPrimaryGradient)
    //         .clipShape(RoundedRectangle(cornerRadius: 12))
    //         .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    //         .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    // }
    
    // static let secondaryButtonStyle = PrimitiveButtonStyle { configuration in
    //     configuration.label
    //         .font(.system(size: 16, weight: .semibold))
    //         .foregroundStyle(MatrimonyColors.matrimonyPrimary)
    //         .frame(maxWidth: .infinity)
    //         .padding(.vertical, 16)
    //         .background(MatrimonyColors.matrimonySecondary)
    //         .clipShape(RoundedRectangle(cornerRadius: 12))
    //         .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    //         .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    // }
    
    // Card Styles - TODO: Fix 'some View' property definitions
    // static let primaryCardStyle = RoundedRectangle(cornerRadius: 16)
    //     .fill(Color.white)
    //     .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    
    // static let elevatedCardStyle = RoundedRectangle(cornerRadius: 16)
    //     .fill(Color.white)
    //     .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
}

// MARK: - Typography for Matrimony

// TODO: Move these enum definitions to appropriate location
enum HeadingSize {
    case h1, h2, h3, h4, h5, h6
}

enum BodySize {
    case small, medium, large
}

@available(iOS 17, *)
struct MatrimonyTypography {
    // Heading Styles
    static func heading(_ size: HeadingSize, weight: Font.Weight = .bold) -> Font {
        switch size {
        case .h1:
            return .system(size: 32, weight: weight, design: .rounded)
        case .h2:
            return .system(size: 24, weight: weight, design: .rounded)
        case .h3:
            return .system(size: 20, weight: weight, design: .rounded)
        case .h4:
            return .system(size: 18, weight: weight, design: .rounded)
        case .h5:
            return .system(size: 16, weight: weight, design: .rounded)
        case .h6:
            return .system(size: 14, weight: weight, design: .rounded)
        }
    }
    
    // Body Styles
    static func body(size: BodySize = .medium, weight: Font.Weight = .regular) -> Font {
        switch size {
        case .small:
            return .system(size: 14, weight: weight)
        case .medium:
            return .system(size: 16, weight: weight)
        case .large:
            return .system(size: 18, weight: weight)
        }
    }
    
    // Caption Styles
    static func caption(weight: Font.Weight = .regular) -> Font {
        .system(size: 12, weight: weight)
    }
    
    // Special Styles
    static func sacredText(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }
    
    static func traditionalText(size: CGFloat = 14) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }
}

// MARK: - Component Styles

@available(iOS 17, *)
struct MatrimonyComponentStyles {
    // Profile Card Style
    static func profileCardStyle() -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.white)
            .shadow(color: MatrimonyColors.matrimonyPrimary.opacity(0.1), radius: 15, x: 0, y: 8)
    }
    
    // Sacred Badge Style
    static func sacredBadgeStyle() -> some View {
        Capsule()
            .fill(MatrimonyColors.matrimonySacredGradient)
            .shadow(color: MatrimonyColors.matrimonySacred.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    // Family Badge Style
    static func familyBadgeStyle() -> some View {
        Capsule()
            .fill(MatrimonyColors.matrimonyFamily)
            .shadow(color: MatrimonyColors.matrimonyFamily.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    // Tradition Badge Style
    static func traditionBadgeStyle() -> some View {
        Capsule()
            .fill(MatrimonyColors.matrimonyTradition)
            .shadow(color: MatrimonyColors.matrimonyTradition.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    // Input Field Style
    static func inputFieldStyle() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(MatrimonyColors.matrimonySecondary, lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
    }
    
    // Selected Input Field Style
    static func selectedInputFieldStyle() -> some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(MatrimonyColors.matrimonyPrimary, lineWidth: 2)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(MatrimonyColors.matrimonyPrimary.opacity(0.05))
            )
    }
}

// MARK: - Animation Constants

@available(iOS 17, *)
struct MatrimonyAnimations {
    static let defaultDuration: Double = 0.3
    static let slowDuration: Double = 0.5
    static let fastDuration: Double = 0.15
    
    static let defaultEase = Animation.easeInOut(duration: defaultDuration)
    static let slowEase = Animation.easeInOut(duration: slowDuration)
    static let fastEase = Animation.easeInOut(duration: fastDuration)
    
    static let springAnimation = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let bouncyAnimation = Animation.spring(response: 0.6, dampingFraction: 0.6)
}

#endif
