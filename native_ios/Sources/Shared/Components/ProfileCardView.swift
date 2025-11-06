#if os(iOS)
import SwiftUI

/**
 * Reusable Profile Card Component
 * 
 * A consistent profile card component used across the app for displaying
 * user profiles in search results, shortlists, matches, and other contexts.
 * 
 * Features:
 * - Async image loading with fallbacks
 * - Profile information display (name, age, location, bio)
 * - Interest tags with horizontal scrolling
 * - Tap gesture handling
 * - Consistent styling and animations
 * - Responsive design
 */
@available(iOS 17, *)
public struct ProfileCardView: View {
    
    // MARK: - Properties
    
    /// Profile data to display
    public let profile: ProfileSummary
    
    /// Action to perform when card is tapped
    public let onTap: (() -> Void)?
    
    /// Card style variant
    public let style: ProfileCardStyle
    
    /// Optional custom corner radius
    public let cornerRadius: CGFloat
    
    /// Optional custom shadow
    public let shadow: ProfileCardShadow
    
    // MARK: - Initialization
    
    public init(
        profile: ProfileSummary,
        onTap: (() -> Void)? = nil,
        style: ProfileCardStyle = .default,
        cornerRadius: CGFloat = 20,
        shadow: ProfileCardShadow = .medium
    ) {
        self.profile = profile
        self.onTap = onTap
        self.style = style
        self.cornerRadius = cornerRadius
        self.shadow = shadow
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack(alignment: .bottom) {
            // Background image
            backgroundImage
            
            // Gradient overlay
            gradientOverlay
            
            // Profile information
            profileInfo
        }
        .background(style.backgroundColor)
        .cornerRadius(cornerRadius)
        .applyShadow(shadow)
        .conditionalTapGesture(onTap)
        .scaleEffect(style.scaleEffect)
        .opacity(style.opacity)
        .animation(.easeInOut(duration: 0.2), value: style.scaleEffect)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var backgroundImage: some View {
        Group {
            if let url = profile.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        loadingPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }
    
    @ViewBuilder
    private var loadingPlaceholder: some View {
        Color.gray.opacity(0.3)
            .overlay(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AroosiColors.primary))
                    .scaleEffect(0.8)
            )
    }
    
    @ViewBuilder
    private var placeholderImage: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AroosiColors.primary.opacity(0.3),
                    AroosiColors.primaryDark.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "person.circle.fill")
                .font(.system(size: style.imageSize))
                .foregroundStyle(AroosiColors.primary.opacity(0.5))
        }
    }
    
    @ViewBuilder
    private var gradientOverlay: some View {
        LinearGradient(
            colors: style.gradientColors,
            startPoint: .center,
            endPoint: .bottom
        )
    }
    
    @ViewBuilder
    private var profileInfo: some View {
        VStack(alignment: .leading, spacing: style.spacing) {
            // Name and age
            nameAndAgeSection
            
            // Location
            if let location = profile.location, !location.isEmpty {
                locationSection
            }
            
            // Bio
            if let bio = profile.bio, !bio.isEmpty {
                bioSection
            }
            
            // Interests
            if !profile.interests.isEmpty {
                interestsSection
            }
        }
        .padding(style.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var nameAndAgeSection: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Text(profile.displayName)
                .font(style.nameFont)
                .foregroundStyle(.white)
            
            if let age = profile.age {
                Text("\(age)")
                    .font(style.ageFont)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }
    
    @ViewBuilder
    private var locationSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 16))
            Text(profile.location ?? "")
                .font(style.locationFont)
        }
        .foregroundStyle(.white)
    }
    
    @ViewBuilder
    private var bioSection: some View {
        Text(profile.bio ?? "")
            .font(style.bioFont)
            .foregroundStyle(.white.opacity(0.9))
            .lineLimit(style.bioLineLimit)
    }
    
    @ViewBuilder
    private var interestsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(profile.interests.prefix(style.maxInterests).enumerated()), id: \.offset) { index, interest in
                    InterestTagView(
                        text: interest,
                        style: style.interestTagStyle
                    )
                }
                
                // Show "more" indicator if there are more interests
                if profile.interests.count > style.maxInterests {
                    Text("+\(profile.interests.count - style.maxInterests)")
                        .font(AroosiTypography.caption(size: 13))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(AroosiColors.muted.opacity(0.8), in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func conditionalTapGesture(_ handler: (() -> Void)?) -> some View {
        if let handler {
            onTapGesture(perform: handler)
        } else {
            self
        }
    }
}

// MARK: - Profile Card Styles

@available(iOS 17, *)
public struct ProfileCardStyle {
    public let backgroundColor: Color
    public let gradientColors: [Color]
    public let nameFont: Font
    public let ageFont: Font
    public let locationFont: Font
    public let bioFont: Font
    public let interestTagStyle: InterestTagStyle
    public let padding: EdgeInsets
    public let spacing: CGFloat
    public let bioLineLimit: Int
    public let maxInterests: Int
    public let imageSize: CGFloat
    public let scaleEffect: CGFloat
    public let opacity: Double
    
    public static let `default` = ProfileCardStyle(
        backgroundColor: AroosiColors.surface,
        gradientColors: [
            Color.clear,
            Color.black.opacity(0.3),
            Color.black.opacity(0.7)
        ],
        nameFont: AroosiTypography.heading(size: 32, weight: .bold),
        ageFont: AroosiTypography.heading(size: 28, weight: .semibold),
        locationFont: AroosiTypography.body(size: 16),
        bioFont: AroosiTypography.body(),
        interestTagStyle: .default,
        padding: EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24),
        spacing: 12,
        bioLineLimit: 2,
        maxInterests: 5,
        imageSize: 120,
        scaleEffect: 1.0,
        opacity: 1.0
    )
    
    public static let compact = ProfileCardStyle(
        backgroundColor: AroosiColors.surface,
        gradientColors: [
            Color.clear,
            Color.black.opacity(0.2),
            Color.black.opacity(0.6)
        ],
        nameFont: AroosiTypography.heading(size: 24, weight: .bold),
        ageFont: AroosiTypography.heading(size: 20, weight: .semibold),
        locationFont: AroosiTypography.body(size: 14),
        bioFont: AroosiTypography.caption(),
        interestTagStyle: .compact,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        spacing: 8,
        bioLineLimit: 1,
        maxInterests: 3,
        imageSize: 80,
        scaleEffect: 1.0,
        opacity: 1.0
    )
    
    public static let prominent = ProfileCardStyle(
        backgroundColor: AroosiColors.surface,
        gradientColors: [
            Color.clear,
            Color.black.opacity(0.4),
            Color.black.opacity(0.8)
        ],
        nameFont: AroosiTypography.heading(size: 36, weight: .bold),
        ageFont: AroosiTypography.heading(size: 32, weight: .semibold),
        locationFont: AroosiTypography.body(size: 18),
        bioFont: AroosiTypography.body(),
        interestTagStyle: .prominent,
        padding: EdgeInsets(top: 32, leading: 32, bottom: 32, trailing: 32),
        spacing: 16,
        bioLineLimit: 3,
        maxInterests: 6,
        imageSize: 140,
        scaleEffect: 1.0,
        opacity: 1.0
    )
}

// MARK: - Profile Card Shadow

@available(iOS 17, *)
public struct ProfileCardShadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    
    public static let none = ProfileCardShadow(color: .clear, radius: 0, x: 0, y: 0)
    public static let light = ProfileCardShadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    public static let `medium` = ProfileCardShadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    public static let heavy = ProfileCardShadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
}

// MARK: - Shadow Extension

extension View {
    @ViewBuilder
    func applyShadow(_ shadow: ProfileCardShadow) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}

// MARK: - Interest Tag Component

@available(iOS 17, *)
public struct InterestTagView: View {
    public let text: String
    public let style: InterestTagStyle
    
    public init(text: String, style: InterestTagStyle = .default) {
        self.text = text
        self.style = style
    }
    
    public var body: some View {
        Text(text)
            .font(style.font)
            .padding(style.padding)
            .background(style.backgroundColor, in: Capsule())
            .foregroundStyle(style.textColor)
    }
}

// MARK: - Interest Tag Styles

@available(iOS 17, *)
public struct InterestTagStyle {
    public let font: Font
    public let textColor: Color
    public let backgroundColor: Color
    public let padding: EdgeInsets
    
    public static let `default` = InterestTagStyle(
        font: AroosiTypography.caption(size: 13),
        textColor: .white,
        backgroundColor: AroosiColors.primary.opacity(0.8),
        padding: EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
    )
    
    public static let compact = InterestTagStyle(
        font: AroosiTypography.caption(size: 11),
        textColor: .white,
        backgroundColor: AroosiColors.primary.opacity(0.7),
        padding: EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
    )
    
    public static let prominent = InterestTagStyle(
        font: AroosiTypography.caption(size: 14),
        textColor: .white,
        backgroundColor: AroosiColors.primary.opacity(0.9),
        padding: EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    )
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
    ProfileCardView(
        profile: ProfileSummary(
            id: "preview",
            displayName: "Aisha Khan",
            age: 28,
            location: "Kabul, Afghanistan",
            bio: "Passionate about education and family values. Looking for a compatible partner.",
            avatarURL: URL(string: "https://picsum.photos/400/600"),
            interests: ["Education", "Family", "Reading", "Travel", "Cooking"]
        ),
        onTap: {
            print("Profile card tapped!")
        }
    )
    .padding()
    .background(AroosiColors.background)
}

#endif
