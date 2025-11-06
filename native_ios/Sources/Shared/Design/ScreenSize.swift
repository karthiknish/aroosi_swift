import SwiftUI

#if canImport(UIKit)
import UIKit

/// Screen size utilities for responsive iPhone layouts
@available(iOS 17.0.0, *)
public enum ScreenSize {
    // MARK: - Device Types (iPhone-specific)
    
    /// iPhone SE, Mini devices (< 667pt height)
    public static var isSmallDevice: Bool {
        screenHeight < 667
    }
    
    /// Standard iPhones 12-15 (667-844pt height)
    public static var isMediumDevice: Bool {
        screenHeight >= 667 && screenHeight < 844
    }
    
    /// Plus models (844-896pt height)
    public static var isLargeDevice: Bool {
        screenHeight >= 844 && screenHeight < 932
    }
    
    /// Pro Max models (896pt+ height)
    public static var isProMaxDevice: Bool {
        screenHeight >= 932
    }
    
    // MARK: - Screen Dimensions
    
    public static var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    public static var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    public static var safeAreaInsets: UIEdgeInsets {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return window?.safeAreaInsets ?? .zero
    }
    
    /// Usable height accounting for safe area
    public static var usableHeight: CGFloat {
        screenHeight - safeAreaInsets.top - safeAreaInsets.bottom
    }
    
    /// Usable width accounting for safe area
    public static var usableWidth: CGFloat {
        screenWidth - safeAreaInsets.left - safeAreaInsets.right
    }
    
    // MARK: - Responsive Spacing
    
    public static func spacing(small: CGFloat = 8, medium: CGFloat = 12, large: CGFloat = 16, proMax: CGFloat = 20) -> CGFloat {
        if isSmallDevice { return small }
        if isMediumDevice { return medium }
        if isLargeDevice { return large }
        return proMax
    }
    
    public static func padding(small: CGFloat = 12, medium: CGFloat = 16, large: CGFloat = 20, proMax: CGFloat = 24) -> CGFloat {
        if isSmallDevice { return small }
        if isMediumDevice { return medium }
        if isLargeDevice { return large }
        return proMax
    }
    
    // MARK: - Responsive Font Sizes
    
    public static func fontSize(small: CGFloat = 14, medium: CGFloat = 16, large: CGFloat = 18, proMax: CGFloat = 20) -> CGFloat {
        if isSmallDevice { return small }
        if isMediumDevice { return medium }
        if isLargeDevice { return large }
        return proMax
    }
    
    /// Scale a base font size proportionally to device size
    public static func scaledFont(base: CGFloat) -> CGFloat {
        let scale: CGFloat
        if isSmallDevice { scale = 0.9 }
        else if isMediumDevice { scale = 1.0 }
        else if isLargeDevice { scale = 1.05 }
        else { scale = 1.1 }
        return base * scale
    }
    
    // MARK: - Layout Helpers
    
    /// Get optimal card/image height for profile cards
    public static var cardHeight: CGFloat {
        if isSmallDevice { return usableHeight * 0.60 }      // 60% for small
        if isMediumDevice { return usableHeight * 0.65 }     // 65% for medium
        if isLargeDevice { return usableHeight * 0.68 }      // 68% for large
        return usableHeight * 0.70                            // 70% for Pro Max
    }
    
    /// Get optimal card width
    public static var cardWidth: CGFloat {
        screenWidth * 0.90  // 90% of screen width for all devices
    }
    
    /// Button height for different screen sizes
    public static var buttonHeight: CGFloat {
        if isSmallDevice { return 44 }
        if isMediumDevice { return 48 }
        if isLargeDevice { return 52 }
        return 56
    }
    
    /// Minimum touch target (Apple HIG recommends 44pt)
    public static let minTouchTarget: CGFloat = 44
}

// MARK: - View Extensions for Responsive Design

@available(iOS 17.0.0, *)
public extension View {
    /// Apply padding that adapts to screen size
    func responsivePadding(_ edges: Edge.Set = .all) -> some View {
        self.padding(edges, ScreenSize.padding())
    }
    
    /// Apply corner radius that adapts to screen size
    func responsiveCornerRadius() -> some View {
        self.cornerRadius(ScreenSize.isSmallDevice ? 8 : ScreenSize.isProMaxDevice ? 16 : 12)
    }
    
    /// Apply font size that adapts to screen size and supports Dynamic Type
    func responsiveFontSize() -> some View {
        self.font(.system(size: ScreenSize.fontSize(), weight: .regular))
            .minimumScaleFactor(0.8)
    }
    
    /// Apply accessible font with Dynamic Type support
    func accessibleFont(baseSize: CGFloat = 16, weight: Font.Weight = .regular) -> some View {
        self.font(.system(size: ScreenSize.scaledFont(base: baseSize), weight: weight))
            .minimumScaleFactor(0.8)
            .lineLimit(nil)
    }
    
    /// Orientation-aware padding
    func orientationPadding() -> some View {
        GeometryReader { proxy in
            let isLandscape = proxy.size.width > proxy.size.height
            let padding = isLandscape ? 
                ScreenSize.padding(small: 8, medium: 12, large: 16, proMax: 20) :
                ScreenSize.padding()
            self.padding(padding)
        }
    }
    
    /// Safe area aware frame
    func safeAreaFrame() -> some View {
        GeometryReader { proxy in
            let safeArea = ScreenSize.safeAreaInsets
            let usableWidth = proxy.size.width - safeArea.left - safeArea.right
            let usableHeight = proxy.size.height - safeArea.top - safeArea.bottom
            
            self.frame(width: usableWidth, height: usableHeight)
        }
    }
    
    /// iPad-optimized layout
    func iPadLayout() -> some View {
        GeometryReader { proxy in
            let isTablet = ScreenSize.screenWidth >= 744
            let isLandscape = proxy.size.width > proxy.size.height
            
            if isTablet {
                // Tablet-specific layout
                self.frame(maxWidth: isLandscape ? .infinity : 600)
                    .padding(isLandscape ? 32 : 24)
            } else {
                // Phone layout
                self.frame(maxWidth: .infinity)
                    .padding(ScreenSize.padding())
            }
        }
    }
}

#endif
