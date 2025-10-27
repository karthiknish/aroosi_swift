import SwiftUI

@available(iOS 17.0.0, *)
public enum iPhoneSize {
    case mini      // iPhone SE, Mini (width <= 375)
    case standard  // iPhone 12-15 (376-390)
    case plus      // iPhone Plus models (391-428)
    case proMax    // iPhone Pro Max (429+)
}

@available(iOS 17.0.0, *)
public enum Responsive {
    /// Determine iPhone size category based on width
    public static func iPhoneSize(for width: CGFloat) -> iPhoneSize {
        switch width {
        case ...375: return .mini
        case 376...390: return .standard
        case 391...428: return .plus
        default: return .proMax
        }
    }
    
    /// Check if this is a small iPhone (Mini, SE)
    public static func isSmallPhone(width: CGFloat) -> Bool {
        width <= 375
    }
    
    /// Check if this is a large iPhone (Plus, Pro Max)
    public static func isLargePhone(width: CGFloat) -> Bool {
        width >= 391
    }

    /// Adaptive screen padding based on iPhone size
    public static func screenPadding(width: CGFloat) -> EdgeInsets {
        let size = iPhoneSize(for: width)
        switch size {
        case .mini:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .standard:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .plus:
            return EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        case .proMax:
            return EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        }
    }

    /// Adaptive content padding
    public static func contentPadding(width: CGFloat) -> EdgeInsets {
        let size = iPhoneSize(for: width)
        switch size {
        case .mini:
            return EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        case .standard:
            return EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        case .plus:
            return EdgeInsets(top: 18, leading: 18, bottom: 18, trailing: 18)
        case .proMax:
            return EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        }
    }

    /// Adaptive spacing with multiplier
    public static func spacing(width: CGFloat, multiplier: Double = 1) -> CGFloat {
        let base: CGFloat = isSmallPhone(width: width) ? 12 : isLargePhone(width: width) ? 20 : 16
        return base * multiplier
    }
    
    /// Adaptive font scaling
    public static func fontSize(base: CGFloat, width: CGFloat) -> CGFloat {
        let size = iPhoneSize(for: width)
        let scale: CGFloat
        switch size {
        case .mini: scale = 0.9
        case .standard: scale = 1.0
        case .plus: scale = 1.05
        case .proMax: scale = 1.1
        }
        return base * scale
    }

    /// Grid columns for different iPhone sizes
    public static func gridColumns(width: CGFloat) -> Int {
        isSmallPhone(width: width) ? 2 : 2  // Always 2 columns for iPhones
    }

    /// Maximum visible items based on screen size
    public static func maxListItems(width: CGFloat) -> Int {
        let size = iPhoneSize(for: width)
        switch size {
        case .mini: return 5
        case .standard: return 6
        case .plus: return 7
        case .proMax: return 8
        }
    }
    
    /// Adaptive card dimensions
    public static func cardSize(width: CGFloat, height: CGFloat) -> CGSize {
        let size = iPhoneSize(for: width)
        let cardWidth: CGFloat
        let cardHeight: CGFloat
        
        switch size {
        case .mini:
            cardWidth = width * 0.85  // 85% of screen width
            cardHeight = height * 0.65 // 65% of screen height
        case .standard:
            cardWidth = width * 0.88
            cardHeight = height * 0.68
        case .plus:
            cardWidth = width * 0.90
            cardHeight = height * 0.70
        case .proMax:
            cardWidth = width * 0.90
            cardHeight = height * 0.72
        }
        
        return CGSize(width: cardWidth, height: cardHeight)
    }
    
    /// Determine screen type for responsive layouts (always mobile for iPhone app)
    public static func screenType(for width: CGFloat) -> ScreenType {
        // iPhone app - always return mobile
        return .mobile
    }
    
    /// Check if this is a large screen for layout purposes
    public static func isLargeScreen(width: CGFloat) -> Bool {
        return isLargePhone(width: width)
    }
    
    /// Responsive avatar size based on screen width
    public static func avatarSize(for width: CGFloat) -> CGFloat {
        let size = iPhoneSize(for: width)
        switch size {
        case .mini: return 40
        case .standard: return 48
        case .plus: return 52
        case .proMax: return 56
        }
    }
    
    /// Responsive button height based on screen width
    public static func buttonHeight(for width: CGFloat) -> CGFloat {
        let size = iPhoneSize(for: width)
        switch size {
        case .mini: return 44
        case .standard: return 48
        case .plus: return 52
        case .proMax: return 56
        }
    }
    
    /// Responsive icon width based on screen width
    public static func iconWidth(for width: CGFloat) -> CGFloat {
        let size = iPhoneSize(for: width)
        switch size {
        case .mini: return 20
        case .standard: return 24
        case .plus: return 26
        case .proMax: return 28
        }
    }
    
    /// Responsive height for media components
    public static func mediaHeight(for width: CGFloat, type: MediaType) -> CGFloat {
        let size = iPhoneSize(for: width)
        let baseHeight: CGFloat
        switch type {
        case .thumbnail: baseHeight = 80
        case .card: baseHeight = 120
        case .banner: baseHeight = 200
        case .gallery: baseHeight = 260
        }
        
        let multiplier: CGFloat
        switch size {
        case .mini: multiplier = 0.8
        case .standard: multiplier = 1.0
        case .plus: multiplier = 1.1
        case .proMax: multiplier = 1.2
        }
        
        return baseHeight * multiplier
    }
    
    public enum MediaType {
        case thumbnail
        case card
        case banner
        case gallery
    }
    
    /// Responsive frame size for common components
    public static func frameSize(for width: CGFloat, type: FrameType) -> CGSize {
        let size = iPhoneSize(for: width)
        switch type {
        case .smallSquare:
            let dimension: CGFloat
            switch size {
            case .mini: dimension = 60
            case .standard: dimension = 72
            case .plus: dimension = 80
            case .proMax: dimension = 88
            }
            return CGSize(width: dimension, height: dimension)
            
        case .mediumSquare:
            let dimension: CGFloat
            switch size {
            case .mini: dimension = 100
            case .standard: dimension = 120
            case .plus: dimension = 130
            case .proMax: dimension = 140
            }
            return CGSize(width: dimension, height: dimension)
            
        case .largeSquare:
            let dimension: CGFloat
            switch size {
            case .mini: dimension = 160
            case .standard: dimension = 200
            case .plus: dimension = 220
            case .proMax: dimension = 240
            }
            return CGSize(width: dimension, height: dimension)
        }
    }
    
    public enum FrameType {
        case smallSquare
        case mediumSquare
        case largeSquare
    }
    
    public enum ScreenType {
        case mobile
        case tablet
        case desktop
    }
}

@available(iOS 15.0.15, *)
public struct ResponsiveLayout<Mobile: View, Tablet: View, Desktop: View>: View {
    private let mobile: () -> Mobile
    private let tablet: () -> Tablet
    private let desktop: () -> Desktop

    public init(@ViewBuilder mobile: @escaping () -> Mobile,
                @ViewBuilder tablet: @escaping () -> Tablet,
                @ViewBuilder desktop: @escaping () -> Desktop) {
        self.mobile = mobile
        self.tablet = tablet
        self.desktop = desktop
    }

    public var body: some View {
        GeometryReader { proxy in
            let type = Responsive.screenType(for: proxy.size.width)
            Group {
                switch type {
                case .mobile:
                    mobile()
                case .tablet:
                    tablet()
                case .desktop:
                    desktop()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
        }
    }
}

@available(iOS 15.0.15, *)
public struct AdaptiveContainer<Content: View>: View {
    private let content: () -> Content
    private let maxWidth: CGFloat?
    private let alignment: Alignment

    public init(maxWidth: CGFloat? = nil,
                alignment: Alignment = .top,
                @ViewBuilder content: @escaping () -> Content) {
        self.maxWidth = maxWidth
        self.alignment = alignment
        self.content = content
    }

    public var body: some View {
        GeometryReader { proxy in
            let padding = Responsive.screenPadding(width: proxy.size.width)
            VStack(alignment: .leading, spacing: AroosiSpacing.lg) {
                content()
            }
            .frame(maxWidth: maxWidth ?? (Responsive.screenType(for: proxy.size.width) == .desktop ? 1200 : .infinity), alignment: alignment)
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .background(AroosiColors.background)
        }
    }
}
