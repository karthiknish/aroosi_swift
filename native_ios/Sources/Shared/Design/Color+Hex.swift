import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 15.0.15, *)
extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let red = Double((hex & 0xFF0000) >> 16) / 255.0
        let green = Double((hex & 0x00FF00) >> 8) / 255.0
        let blue = Double(hex & 0x0000FF) / 255.0
        self = Color(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    // MARK: - Brand Colors
    
    /// Primary brand color for Aroosi app
    static var aroosi: Color {
        Color(hex: 0xE91E63) // Pink/Rose color
    }
    
    /// Secondary brand color
    static var aroosiSecondary: Color {
        Color(hex: 0x9C27B0) // Purple
    }
    
    /// Accent color for highlights
    static var aroosiAccent: Color {
        Color(hex: 0xFF4081) // Light Pink
    }
    
    #if canImport(UIKit)
    static var systemBackground: Color {
        Color(uiColor: .systemBackground)
    }
    
    static var secondarySystemBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }
    
    static var tertiarySystemBackground: Color {
        Color(uiColor: .tertiarySystemBackground)
    }
    #endif
}
