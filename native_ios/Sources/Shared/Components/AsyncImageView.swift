#if os(iOS)
import SwiftUI

/**
 * Reusable Async Image Component
 * 
 * A consistent async image loading component used across the app for displaying
 * remote images with proper loading states, error handling, and fallbacks.
 * 
 * Features:
 * - Async image loading with progress indicators
 * - Customizable placeholder images
 * - Error handling with fallback options
 * - Multiple shape options (circle, rounded rectangle, rectangle)
 * - Configurable sizing and aspect ratios
 * - Caching and performance optimization
 * - Accessibility support
 */
@available(iOS 17, *)
public struct AsyncImageView: View {
    
    // MARK: - Properties
    
    /// URL of the image to load
    public let url: URL?
    
    /// Image shape style
    public let shape: AsyncImageShape
    
    /// Image size
    public let size: AsyncImageSize
    
    /// Placeholder configuration
    public let placeholder: AsyncImagePlaceholder
    
    /// Loading configuration
    public let loading: AsyncImageLoading
    
    /// Error handling configuration
    public let errorHandling: AsyncImageErrorHandling
    
    // MARK: - Initialization
    
    public init(
        url: URL?,
        shape: AsyncImageShape = .circle,
        size: AsyncImageSize = .medium,
        placeholder: AsyncImagePlaceholder = .default,
        loading: AsyncImageLoading = .default,
        errorHandling: AsyncImageErrorHandling = .default
    ) {
        self.url = url
        self.shape = shape
        self.size = size
        self.placeholder = placeholder
        self.loading = loading
        self.errorHandling = errorHandling
    }
    
    // MARK: - Body
    
    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                loadingView
            case .success(let image):
                successView(image)
            case .failure:
                failureView
            @unknown default:
                failureView
            }
        }
        .applyShape(shape)
        .applySize(size)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var loadingView: some View {
        Group {
            if loading.showPlaceholder {
                placeholderView
                    .overlay(loadingIndicator)
            } else {
                loadingIndicator
            }
        }
    }
    
    @ViewBuilder
    private var successView: some View {
        Group {
            if shape == .circle {
                Image(uiImage: $0)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Image(uiImage: $0)
                    .resizable()
                    .aspectRatio(contentMode: size.aspectRatio)
            }
        }
    }
    
    @ViewBuilder
    private var failureView: some View {
        Group {
            if errorHandling.usePlaceholder {
                placeholderView
                    .overlay(errorOverlay)
            } else {
                defaultErrorView
            }
        }
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        Group {
            switch placeholder.type {
            case .gradient:
                gradientPlaceholder
            case .icon:
                iconPlaceholder
            case .custom(let view):
                view
            case .avatar(let name):
                avatarPlaceholder(name: name)
            }
        }
    }
    
    @ViewBuilder
    private var gradientPlaceholder: some View {
        LinearGradient(
            colors: placeholder.colors,
            startPoint: placeholder.startPoint,
            endPoint: placeholder.endPoint
        )
    }
    
    @ViewBuilder
    private var iconPlaceholder: some View {
        ZStack {
            gradientPlaceholder
            Image(systemName: placeholder.iconName)
                .font(.system(size: placeholder.iconSize))
                .foregroundStyle(placeholder.iconColor)
        }
    }
    
    @ViewBuilder
    private var avatarPlaceholder: some View {
        ZStack {
            gradientPlaceholder
            Text(placeholder.initials)
                .font(placeholder.font)
                .foregroundStyle(placeholder.textColor)
        }
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        if loading.showIndicator {
            ProgressView()
                .progressViewStyle(
                    CircularProgressViewStyle(
                        tint: loading.color
                    )
                )
                .scaleEffect(loading.scale)
        }
    }
    
    @ViewBuilder
    private var errorOverlay: some View {
        if errorHandling.showIcon {
            VStack(spacing: 8) {
                Image(systemName: errorHandling.iconName)
                    .font(.system(size: errorHandling.iconSize))
                    .foregroundStyle(errorHandling.iconColor)
                
                if errorHandling.showText {
                    Text(errorHandling.text)
                        .font(errorHandling.textFont)
                        .foregroundStyle(errorHandling.textColor)
                }
            }
        }
    }
    
    @ViewBuilder
    private var defaultErrorView: some View {
        VStack(spacing: 8) {
            Image(systemName: errorHandling.iconName)
                .font(.system(size: errorHandling.iconSize))
                .foregroundStyle(errorHandling.iconColor)
            
            if errorHandling.showText {
                Text(errorHandling.text)
                    .font(errorHandling.textFont)
                    .foregroundStyle(errorHandling.textColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(errorHandling.backgroundColor)
    }
    
    // MARK: - Computed Properties
    
    private var accessibilityLabel: String {
        if let url = url {
            return "Profile image"
        } else {
            return "No profile image"
        }
    }
}

// MARK: - Async Image Shape

@available(iOS 17, *)
public enum AsyncImageShape {
    case circle
    case roundedRectangle(cornerRadius: CGFloat)
    case rectangle
}

// MARK: - Async Image Size

@available(iOS 17, *)
public enum AsyncImageSize {
    case small
    case medium
    case large
    case custom(width: CGFloat, height: CGFloat)
    case square(CGFloat)
    
    var aspectRatio: ContentMode {
        switch self {
        case .small, .medium, .large, .square:
            return .fill
        case .custom:
            return .fit
        }
    }
}

// MARK: - Shape Extension

extension View {
    @ViewBuilder
    func applyShape(_ shape: AsyncImageShape) -> some View {
        switch shape {
        case .circle:
            self.clipShape(Circle())
        case .roundedRectangle(let cornerRadius):
            self.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .rectangle:
            self.clipShape(Rectangle())
        }
    }
    
    @ViewBuilder
    func applySize(_ size: AsyncImageSize) -> some View {
        switch size {
        case .small:
            self.frame(width: 40, height: 40)
        case .medium:
            self.frame(width: 80, height: 80)
        case .large:
            self.frame(width: 120, height: 120)
        case .custom(let width, let height):
            self.frame(width: width, height: height)
        case .square(let dimension):
            self.frame(width: dimension, height: dimension)
        }
    }
}

// MARK: - Async Image Placeholder

@available(iOS 17, *)
public struct AsyncImagePlaceholder {
    public let type: PlaceholderType
    public let colors: [Color]
    public let startPoint: UnitPoint
    public let endPoint: UnitPoint
    public let iconName: String
    public let iconSize: CGFloat
    public let iconColor: Color
    public let font: Font
    public let textColor: Color
    public let initials: String
    
    public enum PlaceholderType {
        case gradient
        case icon
        case custom(AnyView)
        case avatar(name: String)
    }
    
    public static let `default` = AsyncImagePlaceholder(
        type: .icon,
        colors: [
            AroosiColors.primary.opacity(0.3),
            AroosiColors.primaryDark.opacity(0.3)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
        iconName: "person.circle.fill",
        iconSize: 24,
        iconColor: AroosiColors.primary.opacity(0.5),
        font: AroosiTypography.heading(size: 20, weight: .medium),
        textColor: .white,
        initials: "?"
    )
    
    public static let avatar = AsyncImagePlaceholder(
        type: .avatar(name: ""),
        colors: [
            AroosiColors.primary,
            AroosiColors.primaryDark
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
        iconName: "person.circle.fill",
        iconSize: 32,
        iconColor: .white,
        font: AroosiTypography.heading(size: 28, weight: .bold),
        textColor: .white,
        initials: "?"
    )
}

// MARK: - Async Image Loading

@available(iOS 17, *)
public struct AsyncImageLoading {
    public let showIndicator: Bool
    public let showPlaceholder: Bool
    public let color: Color
    public let scale: CGFloat
    
    public static let `default` = AsyncImageLoading(
        showIndicator: true,
        showPlaceholder: true,
        color: AroosiColors.primary,
        scale: 0.8
    )
    
    public static let minimal = AsyncImageLoading(
        showIndicator: false,
        showPlaceholder: true,
        color: AroosiColors.primary,
        scale: 1.0
    )
    
    public static let prominent = AsyncImageLoading(
        showIndicator: true,
        showPlaceholder: true,
        color: .white,
        scale: 1.2
    )
}

// MARK: - Async Image Error Handling

@available(iOS 17, *)
public struct AsyncImageErrorHandling {
    public let usePlaceholder: Bool
    public let showIcon: Bool
    public let showText: Bool
    public let iconName: String
    public let iconSize: CGFloat
    public let iconColor: Color
    public let text: String
    public let textFont: Font
    public let textColor: Color
    public let backgroundColor: Color
    
    public static let `default` = AsyncImageErrorHandling(
        usePlaceholder: true,
        showIcon: true,
        showText: false,
        iconName: "photo",
        iconSize: 24,
        iconColor: AroosiColors.muted,
        text: "Failed to load image",
        textFont: AroosiTypography.caption(),
        textColor: AroosiColors.muted,
        backgroundColor: AroosiColors.surface
    )
    
    public static let verbose = AsyncImageErrorHandling(
        usePlaceholder: false,
        showIcon: true,
        showText: true,
        iconName: "exclamationmark.triangle",
        iconSize: 24,
        iconColor: AroosiColors.error,
        text: "Image unavailable",
        textFont: AroosiTypography.caption(),
        textColor: AroosiColors.error,
        backgroundColor: AroosiColors.error.opacity(0.1)
    )
}

// MARK: - Convenience Initializers

@available(iOS 17, *)
extension AsyncImageView {
    
    /// Creates a small circular avatar image
    public static func avatar(url: URL?, name: String = "") -> some View {
        AsyncImageView(
            url: url,
            shape: .circle,
            size: .small,
            placeholder: .avatar,
            loading: .minimal,
            errorHandling: .default
        )
    }
    
    /// Creates a medium circular profile image
    public static func profile(url: URL?) -> some View {
        AsyncImageView(
            url: url,
            shape: .circle,
            size: .medium,
            placeholder: .avatar,
            loading: .default,
            errorHandling: .default
        )
    }
    
    /// Creates a large rectangular banner image
    public static func banner(url: URL?) -> some View {
        AsyncImageView(
            url: url,
            shape: .roundedRectangle(cornerRadius: 12),
            size: .custom(width: 350, height: 200),
            placeholder: .default,
            loading: .default,
            errorHandling: .default
        )
    }
    
    /// Creates a thumbnail image
    public static func thumbnail(url: URL?) -> some View {
        AsyncImageView(
            url: url,
            shape: .roundedRectangle(cornerRadius: 8),
            size: .square(60),
            placeholder: .default,
            loading: .minimal,
            errorHandling: .default
        )
    }
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
    VStack(spacing: 20) {
        // Avatar
        AsyncImageView.avatar(
            url: URL(string: "https://picsum.photos/100/100"),
            name: "John Doe"
        )
        
        // Profile
        AsyncImageView.profile(
            url: URL(string: "https://picsum.photos/200/200")
        )
        
        // Banner
        AsyncImageView.banner(
            url: URL(string: "https://picsum.photos/400/200")
        )
        
        // Thumbnail
        AsyncImageView.thumbnail(
            url: URL(string: "https://picsum.photos/100/100")
        )
    }
    .padding()
    .background(AroosiColors.background)
}

#endif
