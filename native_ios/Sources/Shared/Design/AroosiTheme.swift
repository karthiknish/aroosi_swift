#if os(iOS)
import SwiftUI
import CoreText
import UIKit

@available(iOS 17.0.0, *)
public enum AroosiTheme {
    private static var isConfigured = false

    public static func configure() {
        guard !isConfigured else { return }
        FontRegistrar.register()
        isConfigured = true
    }
}

@available(iOS 15.0.15, *)
public enum AroosiColors {
    // MARK: - Primary Brand Colors
    /// Primary brand (Soft Pink) - Main action color
    public static let primary = Color(hex: 0xEC4899) // Pink-500
    /// Primary dark variant for pressed states
    public static let primaryDark = Color(hex: 0xBE185D) // Pink-700
    /// Text/icons on primary color
    public static let onPrimary = Color.white
    
    // MARK: - Secondary & Accent
    /// Secondary brand (Dusty Blue)
    public static let secondary = Color(hex: 0x5F92AC)
    /// Accent color (Muted Gold)
    public static let accent = Color(hex: 0xD6B27C)

    // MARK: - Aurora Gradient Accents
    /// Aurora gradient accent colors for bespoke UI surfaces
    public static let auroraRose = Color(hex: 0xFF8FB7)
    public static let auroraIris = Color(hex: 0xA78BFA)
    public static let auroraSky = Color(hex: 0x7DD3FC)
    public static let auroraSunset = Color(hex: 0xFFB98B)
    public static let auroraBackground = Color(hex: 0xFFF6FB)
    public static let auroraOutline = Color(hex: 0xEC4899, alpha: 0.2)

    // MARK: - Background & Surface
    /// Primary background (Clean white) - light mode only
    public static let background = Color(hex: 0xFFFFFF)
    /// Surface color (White)
    public static let surface = Color(hex: 0xFFFFFF)
    /// Secondary surface (Clean off-white)
    public static let surfaceSecondary = Color(hex: 0xF9F7F5)
    /// Card background (Light gray)
    public static let cardBackground = Color(hex: 0xF8F9FA)
    /// Grouped background (Light mode only)
    public static let groupedBackground = Color(hex: 0xF2F2F7)
    /// Grouped secondary background (Light mode only)
    public static let groupedSecondaryBackground = Color.white
    /// Grouped tertiary background (Light mode only)
    public static let groupedTertiaryBackground = Color.white

    // MARK: - Text Colors
    /// Primary text (Muted Charcoal)
    public static let text = Color(hex: 0x4A4A4A)
    /// Secondary/muted text
    public static let muted = Color(hex: 0x7A7A7A)
    /// On dark backgrounds
    public static let onDark = Color.white

    // MARK: - Borders
    public static let border = Color(hex: 0xE5E7EB)
    public static let borderPrimary = Color(hex: 0xE5E7EB)

    // MARK: - Status Colors
    public static let error = Color(hex: 0xB45E5E)
    public static let success = Color(hex: 0x7BA17D)
    public static let warning = Color(hex: 0xF59E0B)
    public static let info = Color(hex: 0x3B82F6)

    #if canImport(UIKit)
    /// Dynamic iOS system background (adapts to light/dark mode)
    public static let systemBackground = Color(uiColor: .systemBackground)
    /// Secondary system background for grouped surfaces
    public static let secondarySystemBackground = Color(uiColor: .secondarySystemBackground)
    /// Tertiary system background for nested grouped content
    public static let tertiarySystemBackground = Color(uiColor: .tertiarySystemBackground)
    /// Muted grouped background, used for cards and search fields
    public static let mutedSystemBackground = Color(uiColor: .systemGroupedBackground)
    /// System separator color for subtle dividers
    public static let separator = Color(uiColor: .separator)
    #endif
}

@available(iOS 15.0.15, *)
public enum AroosiSpacing {
    /// Extra small spacing (4pt)
    public static let xs: CGFloat = 4
    /// Small spacing (8pt)
    public static let sm: CGFloat = 8
    /// Medium spacing (16pt) - Most common
    public static let md: CGFloat = 16
    /// Large spacing (24pt)
    public static let lg: CGFloat = 24
    /// Extra large spacing (32pt)
    public static let xl: CGFloat = 32
}

// MARK: - Motion & Animation

/// Animation durations matching Flutter motion constants
@available(iOS 17.0.0, *)
public enum AroosiMotionDurations {
    /// Instant micro-interactions (0.08s) - e.g., button press feedback
    public static let instant: Double = 0.08
    
    /// Fast transitions (0.15s) - e.g., toggle switches, checkboxes
    public static let fast: Double = 0.15
    
    /// Short animations (0.2s) - e.g., tooltips, small UI changes
    public static let short: Double = 0.2
    
    /// Medium animations (0.3s) - e.g., sheet presentations, modal transitions
    public static let medium: Double = 0.3
    
    /// Slow animations (0.4s) - e.g., complex UI transformations
    public static let slow: Double = 0.4
    
    /// Page transitions (0.5s) - e.g., navigation, screen changes
    public static let page: Double = 0.5
    
    /// Bounce effects (0.6s) - e.g., celebratory animations
    public static let bounce: Double = 0.6
    
    /// Long animations (0.8s) - e.g., onboarding sequences
    public static let long: Double = 0.8
    
    /// Loop duration (1.2s) - e.g., loading indicators, infinite animations
    public static let loop: Double = 1.2
}

/// Animation curves matching Flutter motion constants
@available(iOS 17.0, *)
public enum AroosiMotionCurves {
    /// Standard ease curve - balanced acceleration/deceleration
    public static let ease: Animation = .easeInOut
    
    /// Ease in - starts slow, accelerates
    public static let easeIn: Animation = .easeIn
    
    /// Ease out - starts fast, decelerates
    public static let easeOut: Animation = .easeOut
    
    /// Spring animation - natural bouncy feel
    public static let spring: Animation = .spring(response: 0.3, dampingFraction: 0.6)
    
    /// Linear motion - constant speed
    public static let linear: Animation = .linear
    
    /// Bouncy spring - exaggerated bounce for emphasis
    public static let bounce: Animation = .spring(response: 0.5, dampingFraction: 0.5)
    
    /// Smooth spring - gentle spring with minimal overshoot
    public static let smooth: Animation = .spring(response: 0.4, dampingFraction: 0.8)
    
    /// Elastic spring - pronounced bounce-back effect
    public static let elastic: Animation = .spring(response: 0.6, dampingFraction: 0.4)
}

// MARK: - Typography

@available(iOS 17.0.0, *)
public enum AroosiTypography {
    /// Heading font name - Boldonse for display/title styles
    private static let headingFontName = "Boldonse"
    
    /// Body font names - Nunito Sans for reading/content
    private static let nunitoRegular = "NunitoSans-Regular"
    private static let nunitoMedium = "NunitoSans-Medium"
    private static let nunitoSemiBold = "NunitoSans-SemiBold"
    private static let nunitoBold = "NunitoSans-Bold"

    public enum HeadingLevel {
        case h1 // 28pt
        case h2 // 24pt
        case h3 // 20pt
        case h4 // 18pt

        var size: CGFloat {
            switch self {
            case .h1: return 28
            case .h2: return 24
            case .h3: return 20
            case .h4: return 18
            }
        }
    }

    public enum BodyWeight {
        case regular    // 400
        case medium     // 500
        case semibold   // 600
        case bold       // 700

        var fontName: String {
            switch self {
            case .regular: return nunitoRegular
            case .medium: return nunitoMedium
            case .semibold: return nunitoSemiBold
            case .bold: return nunitoBold
            }
        }
    }

    /// Create heading text style
    /// - Parameter level: Heading level (h1, h2, h3, h4)
    public static func heading(_ level: HeadingLevel) -> Font {
        Font.custom(headingFontName, size: level.size, relativeTo: .title2)
    }
    
    /// Create heading text style with size and weight (backward compatibility)
    /// - Parameters:
    ///   - size: Font size
    ///   - weight: Font weight
    public static func heading(_ size: CGFloat, weight: BodyWeight = .regular) -> Font {
        body(weight: weight, size: size)
    }

    /// Convenience overload to allow labeled size parameter.
    public static func heading(size: CGFloat, weight: BodyWeight = .regular) -> Font {
        heading(size, weight: weight)
    }

    /// Create body text style
    /// - Parameters:
    ///   - weight: Font weight (regular, medium, semibold, bold)
    ///   - size: Font size (default: 16)
    public static func body(weight: BodyWeight = .regular, size: CGFloat = 16) -> Font {
        Font.custom(weight.fontName, size: size, relativeTo: .body)
    }

    /// Convenience overload to accept labeled size arguments used across legacy views.
    public static func body(size: CGFloat, weight: BodyWeight = .regular) -> Font {
        body(weight: weight, size: size)
    }

    /// Create caption text style
    /// - Parameter weight: Font weight (default: regular)
    public static func caption(weight: BodyWeight = .regular) -> Font {
        Font.custom(weight.fontName, size: 13, relativeTo: .caption)
    }

    /// Convenience overload mirroring historic API that allowed explicit size.
    public static func caption(size: CGFloat, weight: BodyWeight = .regular) -> Font {
        Font.custom(weight.fontName, size: size, relativeTo: .caption)
    }
    
    // MARK: - Responsive Typography Methods
    
    /// Create responsive heading text style
    /// - Parameters:
    ///   - level: Heading level (h1, h2, h3, h4)
    ///   - width: Screen width for responsive sizing
    public static func heading(_ level: HeadingLevel, width: CGFloat) -> Font {
        let responsiveSize = Responsive.fontSize(base: level.size, width: width)
        return Font.custom(headingFontName, size: responsiveSize, relativeTo: .title2)
    }
    
    /// Create responsive body text style
    /// - Parameters:
    ///   - weight: Font weight (regular, medium, semibold, bold)
    ///   - size: Base font size (default: 16)
    ///   - width: Screen width for responsive sizing
    public static func body(weight: BodyWeight = .regular, size: CGFloat = 16, width: CGFloat) -> Font {
        let responsiveSize = Responsive.fontSize(base: size, width: width)
        return Font.custom(weight.fontName, size: responsiveSize, relativeTo: .body)
    }
    
    /// Create responsive caption text style
    /// - Parameters:
    ///   - weight: Font weight (default: regular)
    ///   - width: Screen width for responsive sizing
    public static func caption(weight: BodyWeight = .regular, width: CGFloat) -> Font {
        let responsiveSize = Responsive.fontSize(base: 13, width: width)
        return Font.custom(weight.fontName, size: responsiveSize, relativeTo: .caption)
    }
    
    /// Create responsive custom text style
    /// - Parameters:
    ///   - weight: Font weight (regular, medium, semibold, bold)
    ///   - size: Base font size
    ///   - width: Screen width for responsive sizing
    ///   - textStyle: SwiftUI text style for relative sizing
    public static func custom(weight: BodyWeight = .regular, size: CGFloat, width: CGFloat, textStyle: Font.TextStyle = .body) -> Font {
        let responsiveSize = Responsive.fontSize(base: size, width: width)
        return Font.custom(weight.fontName, size: responsiveSize, relativeTo: textStyle)
    }
}

@available(iOS 17.0.0, *)
private enum FontRegistrar {
    private static let fonts: [(name: String, ext: String)] = [
        ("Boldonse-Regular", "ttf"),
        ("NunitoSans-Regular", "ttf"),
        ("NunitoSans-Medium", "ttf"),
        ("NunitoSans-SemiBold", "ttf"),
        ("NunitoSans-Bold", "ttf")
    ]

    static func register() {
        for font in fonts {
            guard let url = Bundle.module.url(forResource: font.name, withExtension: font.ext, subdirectory: "Fonts") else {
                continue
            }

            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

// MARK: - Animation Modifiers

@available(iOS 17.0.0, *)
public struct AroosiAnimations {
    
    // MARK: - Fade Animations
    
    /// Fade in animation with optional delay
    public struct FadeIn: ViewModifier {
        let duration: Double
        let delay: Double
        @State private var isVisible = false
        
        public init(duration: Double = AroosiMotionDurations.short, delay: Double = 0) {
            self.duration = duration
            self.delay = delay
        }
        
        public func body(content: Content) -> some View {
            content
                .opacity(isVisible ? 1 : 0)
                .onAppear {
                    withAnimation(.easeOut(duration: duration).delay(delay)) {
                        isVisible = true
                    }
                }
        }
    }
    
    /// Fade out animation
    public struct FadeOut: ViewModifier {
        let duration: Double
        @State private var isVisible = true
        
        public init(duration: Double = AroosiMotionDurations.short) {
            self.duration = duration
        }
        
        public func body(content: Content) -> some View {
            content
                .opacity(isVisible ? 1 : 0)
                .onAppear {
                    withAnimation(.easeOut(duration: duration)) {
                        isVisible = false
                    }
                }
        }
    }
    
    // MARK: - Slide Animations
    
    /// Slide in from bottom with spring animation
    public struct SlideInFromBottom: ViewModifier {
        let offset: CGFloat
        let duration: Double
        let delay: Double
        @State private var isVisible = false
        
        public init(offset: CGFloat = 50, duration: Double = AroosiMotionDurations.medium, delay: Double = 0) {
            self.offset = offset
            self.duration = duration
            self.delay = delay
        }
        
        public func body(content: Content) -> some View {
            content
                .offset(y: isVisible ? 0 : offset)
                .onAppear {
                    withAnimation(AroosiMotionCurves.spring.delay(delay)) {
                        isVisible = true
                    }
                }
        }
    }
    
    /// Slide in from leading edge
    public struct SlideInFromLeading: ViewModifier {
        let offset: CGFloat
        let duration: Double
        let delay: Double
        @State private var isVisible = false
        
        public init(offset: CGFloat = 50, duration: Double = AroosiMotionDurations.medium, delay: Double = 0) {
            self.offset = offset
            self.duration = duration
            self.delay = delay
        }
        
        public func body(content: Content) -> some View {
            content
                .offset(x: isVisible ? 0 : -offset)
                .onAppear {
                    withAnimation(.easeOut(duration: duration).delay(delay)) {
                        isVisible = true
                    }
                }
        }
    }
    
    /// Slide in from trailing edge
    public struct SlideInFromTrailing: ViewModifier {
        let offset: CGFloat
        let duration: Double
        let delay: Double
        @State private var isVisible = false
        
        public init(offset: CGFloat = 50, duration: Double = AroosiMotionDurations.medium, delay: Double = 0) {
            self.offset = offset
            self.duration = duration
            self.delay = delay
        }
        
        public func body(content: Content) -> some View {
            content
                .offset(x: isVisible ? 0 : offset)
                .onAppear {
                    withAnimation(.easeOut(duration: duration).delay(delay)) {
                        isVisible = true
                    }
                }
        }
    }
    
    // MARK: - Scale Animations
    
    /// Scale in with spring animation
    public struct ScaleIn: ViewModifier {
        let scale: CGFloat
        let duration: Double
        let delay: Double
        @State private var isVisible = false
        
        public init(scale: CGFloat = 0.8, duration: Double = AroosiMotionDurations.medium, delay: Double = 0) {
            self.scale = scale
            self.duration = duration
            self.delay = delay
        }
        
        public func body(content: Content) -> some View {
            content
                .scaleEffect(isVisible ? 1.0 : scale)
                .onAppear {
                    withAnimation(AroosiMotionCurves.spring.delay(delay)) {
                        isVisible = true
                    }
                }
        }
    }
    
    /// Bounce scale animation for emphasis
    public struct BounceScale: ViewModifier {
        let trigger: Bool
        let scale: CGFloat
        
        public init(trigger: Bool, scale: CGFloat = 1.1) {
            self.trigger = trigger
            self.scale = scale
        }
        
        public func body(content: Content) -> some View {
            content
                .scaleEffect(trigger ? scale : 1.0)
                .animation(AroosiMotionCurves.bounce, value: trigger)
        }
    }
    
    // MARK: - Loading Animations
    
    /// Pulsing animation for loading states
    public struct Pulse: ViewModifier {
        let duration: Double
        @State private var isPulsing = false
        
        public init(duration: Double = AroosiMotionDurations.loop) {
            self.duration = duration
        }
        
        public func body(content: Content) -> some View {
            content
                .opacity(isPulsing ? 0.6 : 1.0)
                .scaleEffect(isPulsing ? 1.05 : 1.0)
                .onAppear {
                    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                        isPulsing.toggle()
                    }
                }
        }
    }
    
    /// Rotating animation for loading indicators
    public struct Rotate: ViewModifier {
        let duration: Double
        @State private var isRotating = false
        
        public init(duration: Double = AroosiMotionDurations.loop) {
            self.duration = duration
        }
        
        public func body(content: Content) -> some View {
            content
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                        isRotating = true
                    }
                }
        }
    }
}

// MARK: - View Extensions for Easy Access

@available(iOS 17.0.0, *)
public extension View {
    
    /// Apply fade in animation
    func fadeIn(duration: Double = AroosiMotionDurations.short, delay: Double = 0) -> some View {
        modifier(AroosiAnimations.FadeIn(duration: duration, delay: delay))
    }
    
    /// Apply fade out animation
    func fadeOut(duration: Double = AroosiMotionDurations.short) -> some View {
        modifier(AroosiAnimations.FadeOut(duration: duration))
    }
    
    /// Apply slide in from bottom animation
    func slideInFromBottom(offset: CGFloat = 50, duration: Double = AroosiMotionDurations.medium, delay: Double = 0) -> some View {
        modifier(AroosiAnimations.SlideInFromBottom(offset: offset, duration: duration, delay: delay))
    }
    
    /// Apply slide in from leading animation
    func slideInFromLeading(offset: CGFloat = 50, duration: Double = AroosiMotionDurations.medium, delay: Double = 0) -> some View {
        modifier(AroosiAnimations.SlideInFromLeading(offset: offset, duration: duration, delay: delay))
    }
    
    /// Apply slide in from trailing animation
    func slideInFromTrailing(offset: CGFloat = 50, duration: Double = AroosiMotionDurations.medium, delay: Double = 0) -> some View {
        modifier(AroosiAnimations.SlideInFromTrailing(offset: offset, duration: duration, delay: delay))
    }
    
    /// Apply scale in animation
    func scaleIn(scale: CGFloat = 0.8, duration: Double = AroosiMotionDurations.medium, delay: Double = 0) -> some View {
        modifier(AroosiAnimations.ScaleIn(scale: scale, duration: duration, delay: delay))
    }
    
    /// Apply bounce scale animation
    func bounceScale(trigger: Bool, scale: CGFloat = 1.1) -> some View {
        modifier(AroosiAnimations.BounceScale(trigger: trigger, scale: scale))
    }
    
    /// Apply pulsing animation
    func pulsing(duration: Double = AroosiMotionDurations.loop) -> some View {
        modifier(AroosiAnimations.Pulse(duration: duration))
    }
    
    /// Apply rotating animation
    func rotating(duration: Double = AroosiMotionDurations.loop) -> some View {
        modifier(AroosiAnimations.Rotate(duration: duration))
    }
}

// MARK: - Custom Loading Views

@available(iOS 17.0.0, *)
public struct AroosiLoadingView: View {
    let size: CGFloat
    let color: Color
    
    public init(size: CGFloat = 40, color: Color = AroosiColors.primary) {
        self.size = size
        self.color = color
    }
    
    public var body: some View {
        Circle()
            .stroke(color.opacity(0.3), lineWidth: 4)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotating()
            )
    }
}

@available(iOS 17.0.0, *)
public struct AroosiPulsingLoadingView: View {
    let size: CGFloat
    let color: Color
    
    public init(size: CGFloat = 40, color: Color = AroosiColors.primary) {
        self.size = size
        self.color = color
    }
    
    public var body: some View {
        Circle()
            .fill(color.opacity(0.8))
            .frame(width: size, height: size)
            .pulsing()
    }
}

@available(iOS 17.0.0, *)
public struct AroosiDotsLoadingView: View {
    let dotCount: Int
    let dotSize: CGFloat
    let color: Color
    
    public init(dotCount: Int = 3, dotSize: CGFloat = 8, color: Color = AroosiColors.primary) {
        self.dotCount = dotCount
        self.dotSize = dotSize
        self.color = color
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<dotCount, id: \.self) { index in
                Circle()
                    .fill(color)
                    .frame(width: dotSize, height: dotSize)
                    .scaleEffect(1.0)
                    .animation(
                        .easeInOut(duration: AroosiMotionDurations.medium)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: true
                    )
            }
        }
        .onAppear {
            // Trigger animation
        }
    }
}

#endif
