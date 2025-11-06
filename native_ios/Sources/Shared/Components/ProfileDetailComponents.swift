#if os(iOS)
import SwiftUI

/**
 * Reusable Profile Detail Components
 * 
 * A collection of consistent profile detail components used across the app
 * for displaying comprehensive profile information.
 * 
 * Features:
 * - Profile header with name, age, location
 * - Bio section with expandable text
 * - Interest tags display
 * - Quick facts section
 * - Photo gallery
 * - Action buttons
 * - Consistent styling and animations
 */

// MARK: - Profile Header Component

@available(iOS 17, *)
public struct ProfileHeaderView: View {
    
    // MARK: - Properties
    
    public let profile: ProfileSummary
    public let style: ProfileHeaderStyle
    
    // MARK: - Initialization
    
    public init(
        profile: ProfileSummary,
        style: ProfileHeaderStyle = .default
    ) {
        self.profile = profile
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: style.spacing) {
            // Name and age
            HStack(alignment: .bottom, spacing: 8) {
                Text(profile.displayName)
                    .font(style.nameFont)
                    .foregroundStyle(style.nameColor)
                
                if let age = profile.age {
                    Text("\(age)")
                        .font(style.ageFont)
                        .foregroundStyle(style.ageColor)
                }
            }
            
            // Location
            if let location = profile.location, !location.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: style.iconSize))
                        .foregroundStyle(style.iconColor)
                    
                    Text(location)
                        .font(style.locationFont)
                        .foregroundStyle(style.locationColor)
                }
            }
            
            // Last active
            if let lastActive = profile.lastActiveAt {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: style.iconSize))
                        .foregroundStyle(style.iconColor)
                    
                    Text("Active \(lastActive, style: .relative) ago")
                        .font(style.lastActiveFont)
                        .foregroundStyle(style.lastActiveColor)
                }
            }
        }
    }
}

// MARK: - Bio Section Component

@available(iOS 17, *)
public struct BioSectionView: View {
    
    // MARK: - Properties
    
    public let bio: String?
    public let style: BioSectionStyle
    @State public var isExpanded: Bool = false
    
    // MARK: - Initialization
    
    public init(
        bio: String?,
        style: BioSectionStyle = .default
    ) {
        self.bio = bio
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: style.spacing) {
            if let bio = bio, !bio.isEmpty {
                HStack {
                    Text("About")
                        .font(style.titleFont)
                        .foregroundStyle(style.titleColor)
                    
                    Spacer()
                    
                    if bio.count > style.expansionThreshold {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "Show Less" : "Show More")
                                .font(style.actionFont)
                                .foregroundStyle(style.actionColor)
                        }
                    }
                }
                
                Text(bio)
                    .font(style.bioFont)
                    .foregroundStyle(style.bioColor)
                    .lineLimit(isExpanded ? nil : style.maxLines)
            }
        }
        .padding(style.padding)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
    }
}

// MARK: - Interests Section Component

@available(iOS 17, *)
public struct InterestsSectionView: View {
    
    // MARK: - Properties
    
    public let interests: [String]
    public let style: InterestsSectionStyle
    
    // MARK: - Initialization
    
    public init(
        interests: [String],
        style: InterestsSectionStyle = .default
    ) {
        self.interests = interests
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: style.spacing) {
            if !interests.isEmpty {
                Text("Interests")
                    .font(style.titleFont)
                    .foregroundStyle(style.titleColor)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: style.columns), spacing: style.itemSpacing) {
                    ForEach(interests, id: \.self) { interest in
                        InterestTagView(
                            text: interest,
                            style: style.tagStyle
                        )
                    }
                }
            }
        }
        .padding(style.padding)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
    }
}

// MARK: - Quick Facts Section Component

@available(iOS 17, *)
public struct QuickFactsSectionView: View {
    
    // MARK: - Properties
    
    public let facts: [QuickFact]
    public let style: QuickFactsStyle
    
    // MARK: - Initialization
    
    public init(
        facts: [QuickFact],
        style: QuickFactsStyle = .default
    ) {
        self.facts = facts
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: style.spacing) {
            if !facts.isEmpty {
                Text("Quick Facts")
                    .font(style.titleFont)
                    .foregroundStyle(style.titleColor)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: style.columns), spacing: style.itemSpacing) {
                    ForEach(facts, id: \.id) { fact in
                        QuickFactView(fact: fact, style: style.factStyle)
                    }
                }
            }
        }
        .padding(style.padding)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
    }
}

// MARK: - Photo Gallery Component

@available(iOS 17, *)
public struct PhotoGalleryView: View {
    
    // MARK: - Properties
    
    public let photos: [String]
    public let style: PhotoGalleryStyle
    @State public var selectedPhotoIndex: Int = 0
    @State public var showingFullScreen: Bool = false
    
    // MARK: - Initialization
    
    public init(
        photos: [String],
        style: PhotoGalleryStyle = .default
    ) {
        self.photos = photos
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: style.spacing) {
            if !photos.isEmpty {
                // Main photo
                AsyncImageView(
                    url: URL(string: photos[selectedPhotoIndex]),
                    shape: .roundedRectangle(cornerRadius: style.cornerRadius),
                    size: .custom(width: style.mainPhotoWidth, height: style.mainPhotoHeight)
                )
                .onTapGesture {
                    showingFullScreen = true
                }
                
                // Photo thumbnails
                if photos.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: style.thumbnailSpacing) {
                            ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                                AsyncImageView(
                                    url: URL(string: photo),
                                    shape: .roundedRectangle(cornerRadius: style.thumbnailCornerRadius),
                                    size: .square(style.thumbnailSize)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: style.thumbnailCornerRadius)
                                        .stroke(
                                            selectedPhotoIndex == index ? style.selectedBorderColor : style.borderColor,
                                            lineWidth: selectedPhotoIndex == index ? style.selectedBorderWidth : style.borderWidth
                                        )
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedPhotoIndex = index
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            PhotoFullScreenView(
                photos: photos,
                selectedIndex: selectedPhotoIndex
            )
        }
    }
}

// MARK: - Profile Actions Component

@available(iOS 17, *)
public struct ProfileActionsView: View {
    
    // MARK: - Properties
    
    public let onLike: () -> Void
    public let onPass: () -> Void
    public let onMessage: (() -> Void)?
    public let style: ProfileActionsStyle
    
    // MARK: - Initialization
    
    public init(
        onLike: @escaping () -> Void,
        onPass: @escaping () -> Void,
        onMessage: (() -> Void)? = nil,
        style: ProfileActionsStyle = .default
    ) {
        self.onLike = onLike
        self.onPass = onPass
        self.onMessage = onMessage
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        HStack(spacing: style.spacing) {
            // Pass button
            ActionButtonView(
                icon: "xmark",
                color: style.passColor,
                size: style.buttonSize,
                action: onPass
            )
            
            // Message button (optional)
            if let onMessage = onMessage {
                ActionButtonView(
                    icon: "message",
                    color: style.messageColor,
                    size: style.buttonSize,
                    action: onMessage
                )
            }
            
            // Like button
            ActionButtonView(
                icon: "heart",
                color: style.likeColor,
                size: style.buttonSize,
                action: onLike
            )
        }
        .padding(style.padding)
        .background(style.backgroundColor)
    }
}

// MARK: - Supporting Components

@available(iOS 17, *)
public struct QuickFact: Identifiable {
    public let id = UUID()
    public let icon: String
    public let label: String
    public let value: String
    
    public init(icon: String, label: String, value: String) {
        self.icon = icon
        self.label = label
        self.value = value
    }
}

@available(iOS 17, *)
public struct QuickFactView: View {
    
    // MARK: - Properties
    
    public let fact: QuickFact
    public let style: QuickFactStyle
    
    // MARK: - Initialization
    
    public init(fact: QuickFact, style: QuickFactStyle = .default) {
        self.fact = fact
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: style.spacing) {
            Image(systemName: fact.icon)
                .font(.system(size: style.iconSize))
                .foregroundStyle(style.iconColor)
            
            Text(fact.label)
                .font(style.labelFont)
                .foregroundStyle(style.labelColor)
            
            Text(fact.value)
                .font(style.valueFont)
                .foregroundStyle(style.valueColor)
        }
        .padding(style.padding)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
    }
}

@available(iOS 17, *)
public struct ActionButtonView: View {
    
    // MARK: - Properties
    
    public let icon: String
    public let color: Color
    public let size: CGFloat
    public let action: () -> Void
    
    // MARK: - Initialization
    
    public init(
        icon: String,
        color: Color,
        size: CGFloat,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.color = color
        self.size = size
        self.action = action
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(color, in: Circle())
                .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 17, *)
public struct PhotoFullScreenView: View {
    
    // MARK: - Properties
    
    public let photos: [String]
    public let selectedIndex: Int
    @Environment(\.dismiss) public var dismiss
    @State public var currentIndex: Int
    
    // MARK: - Initialization
    
    public init(photos: [String], selectedIndex: Int) {
        self.photos = photos
        self.selectedIndex = selectedIndex
        self._currentIndex = State(initialValue: selectedIndex)
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    AsyncImageView(
                        url: URL(string: photo),
                        shape: .rectangle,
                        size: .custom(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .ignoresSafeArea()
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6), in: Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
    }
}

// MARK: - Style Definitions

@available(iOS 17, *)
public struct ProfileHeaderStyle {
    public let nameFont: Font
    public let nameColor: Color
    public let ageFont: Font
    public let ageColor: Color
    public let locationFont: Font
    public let locationColor: Color
    public let lastActiveFont: Font
    public let lastActiveColor: Color
    public let iconSize: CGFloat
    public let iconColor: Color
    public let spacing: CGFloat
    
    public static let `default` = ProfileHeaderStyle(
        nameFont: AroosiTypography.heading(size: 28, weight: .bold),
        nameColor: AroosiColors.text,
        ageFont: AroosiTypography.heading(size: 24, weight: .semibold),
        ageColor: AroosiColors.text,
        locationFont: AroosiTypography.body(size: 16),
        locationColor: AroosiColors.muted,
        lastActiveFont: AroosiTypography.caption(),
        lastActiveColor: AroosiColors.muted,
        iconSize: 16,
        iconColor: AroosiColors.muted,
        spacing: 8
    )
}

@available(iOS 17, *)
public struct BioSectionStyle {
    public let titleFont: Font
    public let titleColor: Color
    public let bioFont: Font
    public let bioColor: Color
    public let actionFont: Font
    public let actionColor: Color
    public let maxLines: Int
    public let expansionThreshold: Int
    public let spacing: CGFloat
    public let padding: EdgeInsets
    public let backgroundColor: Color
    public let cornerRadius: CGFloat
    
    public static let `default` = BioSectionStyle(
        titleFont: AroosiTypography.body(weight: .semibold),
        titleColor: AroosiColors.text,
        bioFont: AroosiTypography.body(),
        bioColor: AroosiColors.text,
        actionFont: AroosiTypography.caption(),
        actionColor: AroosiColors.primary,
        maxLines: 3,
        expansionThreshold: 100,
        spacing: 12,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        backgroundColor: AroosiColors.surface,
        cornerRadius: 12
    )
}

@available(iOS 17, *)
public struct InterestsSectionStyle {
    public let titleFont: Font
    public let titleColor: Color
    public let columns: Int
    public let itemSpacing: CGFloat
    public let tagStyle: InterestTagStyle
    public let spacing: CGFloat
    public let padding: EdgeInsets
    public let backgroundColor: Color
    public let cornerRadius: CGFloat
    
    public static let `default` = InterestsSectionStyle(
        titleFont: AroosiTypography.body(weight: .semibold),
        titleColor: AroosiColors.text,
        columns: 2,
        itemSpacing: 8,
        tagStyle: .prominent,
        spacing: 12,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        backgroundColor: AroosiColors.surface,
        cornerRadius: 12
    )
}

@available(iOS 17, *)
public struct QuickFactsStyle {
    public let titleFont: Font
    public let titleColor: Color
    public let columns: Int
    public let itemSpacing: CGFloat
    public let factStyle: QuickFactStyle
    public let spacing: CGFloat
    public let padding: EdgeInsets
    public let backgroundColor: Color
    public let cornerRadius: CGFloat
    
    public static let `default` = QuickFactsStyle(
        titleFont: AroosiTypography.body(weight: .semibold),
        titleColor: AroosiColors.text,
        columns: 2,
        itemSpacing: 8,
        factStyle: .default,
        spacing: 12,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        backgroundColor: AroosiColors.surface,
        cornerRadius: 12
    )
}

@available(iOS 17, *)
public struct QuickFactStyle {
    public let iconSize: CGFloat
    public let iconColor: Color
    public let labelFont: Font
    public let labelColor: Color
    public let valueFont: Font
    public let valueColor: Color
    public let spacing: CGFloat
    public let padding: EdgeInsets
    public let backgroundColor: Color
    public let cornerRadius: CGFloat
    
    public static let `default` = QuickFactStyle(
        iconSize: 20,
        iconColor: AroosiColors.primary,
        labelFont: AroosiTypography.caption(),
        labelColor: AroosiColors.muted,
        valueFont: AroosiTypography.body(weight: .semibold),
        valueColor: AroosiColors.text,
        spacing: 4,
        padding: EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
        backgroundColor: AroosiColors.surface,
        cornerRadius: 8
    )
}

@available(iOS 17, *)
public struct PhotoGalleryStyle {
    public let mainPhotoWidth: CGFloat
    public let mainPhotoHeight: CGFloat
    public let thumbnailSize: CGFloat
    public let thumbnailSpacing: CGFloat
    public let thumbnailCornerRadius: CGFloat
    public let cornerRadius: CGFloat
    public let borderColor: Color
    public let selectedBorderColor: Color
    public let borderWidth: CGFloat
    public let selectedBorderWidth: CGFloat
    public let spacing: CGFloat
    
    public static let `default` = PhotoGalleryStyle(
        mainPhotoWidth: UIScreen.main.bounds.width - 32,
        mainPhotoHeight: 300,
        thumbnailSize: 60,
        thumbnailSpacing: 8,
        thumbnailCornerRadius: 8,
        cornerRadius: 12,
        borderColor: AroosiColors.border,
        selectedBorderColor: AroosiColors.primary,
        borderWidth: 2,
        selectedBorderWidth: 3,
        spacing: 12
    )
}

@available(iOS 17, *)
public struct ProfileActionsStyle {
    public let buttonSize: CGFloat
    public let spacing: CGFloat
    public let padding: EdgeInsets
    public let backgroundColor: Color
    public let likeColor: Color
    public let passColor: Color
    public let messageColor: Color
    
    public static let `default` = ProfileActionsStyle(
        buttonSize: 60,
        spacing: 20,
        padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
        backgroundColor: AroosiColors.background,
        likeColor: AroosiColors.primary,
        passColor: AroosiColors.error,
        messageColor: AroosiColors.muted
    )
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ProfileHeaderView(
                profile: ProfileSummary(
                    id: "preview",
                    displayName: "Aisha Khan",
                    age: 28,
                    location: "Kabul, Afghanistan",
                    bio: "Passionate about education and family values.",
                    avatarURL: URL(string: "https://picsum.photos/400/400"),
                    interests: ["Education", "Family", "Reading"]
                )
            )
            
            BioSectionView(
                bio: "I am a passionate educator who believes in the power of knowledge to transform lives. Family values are at the core of everything I do, and I'm looking for someone who shares similar beliefs and aspirations."
            )
            
            InterestsSectionView(
                interests: ["Education", "Family", "Reading", "Travel", "Cooking", "Art"]
            )
            
            QuickFactsSectionView(
                facts: [
                    QuickFact(icon: "graduationcap", label: "Education", value: "Master's"),
                    QuickFact(icon: "briefcase", label: "Profession", value: "Teacher"),
                    QuickFact(icon: "heart", label: "Status", value: "Never Married"),
                    QuickFact(icon: "person.2", label: "Family", value: "Traditional")
                ]
            )
            
            ProfileActionsView(
                onLike: { print("Like") },
                onPass: { print("Pass") },
                onMessage: { print("Message") }
            )
        }
        .padding()
    }
    .background(AroosiColors.background)
}

#endif
