import SwiftUI

// MARK: - Responsive Avatar Component

@available(iOS 17.0.0, *)
public struct ResponsiveAvatar: View {
    let url: URL?
    let size: AvatarSize
    let width: CGFloat
    
    public enum AvatarSize {
        case small
        case medium
        case large
        case extraLarge
        
        var baseSize: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 48
            case .large: return 72
            case .extraLarge: return 120
            }
        }
    }
    
    public init(url: URL?, size: AvatarSize = .medium, width: CGFloat) {
        self.url = url
        self.size = size
        self.width = width
    }
    
    public var body: some View {
        let responsiveSize = Responsive.fontSize(base: size.baseSize, width: width)
        
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(.circular)
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                    case .failure:
                        avatarPlaceholder
                    @unknown default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .frame(width: responsiveSize, height: responsiveSize)
        .clipShape(Circle())
        .overlay {
            Circle().stroke(Color(.separator), lineWidth: 1)
        }
    }
    
    private var avatarPlaceholder: some View {
        RoundedRectangle(cornerRadius: responsiveSize / 2)
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: responsiveSize * 0.4))
                    .foregroundStyle(Color.gray)
            }
    }
}

// MARK: - Responsive Card Component

@available(iOS 17.0.0, *)
public struct ResponsiveCard<Content: View>: View {
    let content: Content
    let width: CGFloat
    let height: CGFloat?
    let padding: EdgeInsets?
    let backgroundColor: Color
    let cornerRadius: CGFloat
    
    public init(
        width: CGFloat,
        height: CGFloat? = nil,
        padding: EdgeInsets? = nil,
        backgroundColor: Color = AroosiColors.surfaceSecondary,
        cornerRadius: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.width = width
        self.height = height
        self.padding = padding
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius ?? Responsive.isLargeScreen(width: width) ? 16 : 12
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding ?? Responsive.screenPadding(width: width))
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .applyIfLet(height) { view, height in
                view.frame(height: height)
            }
    }
}

// MARK: - Responsive Button Component

@available(iOS 17.0.0, *)
public struct ResponsiveButton: View {
    let title: String
    let action: () -> Void
    let style: Style
    let width: CGFloat
    let isLoading: Bool
    let isDisabled: Bool
    
    public enum Style {
        case primary
        case secondary
        case outline
        
        var backgroundColor: Color {
            switch self {
            case .primary: return AroosiColors.primary
            case .secondary: return AroosiColors.secondary
            case .outline: return Color.clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .secondary: return .white
            case .outline: return AroosiColors.primary
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .outline: return AroosiColors.primary
            default: return nil
            }
        }
    }
    
    public init(
        title: String,
        action: @escaping () -> Void,
        style: Style = .primary,
        width: CGFloat,
        isLoading: Bool = false,
        isDisabled: Bool = false
    ) {
        self.title = title
        self.action = action
        self.style = style
        self.width = width
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(AroosiTypography.body(weight: .semibold, width: width))
            }
            .foregroundStyle(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: Responsive.buttonHeight(for: width))
            .background(style.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: Responsive.buttonHeight(for: width) / 2)
                    .stroke(style.borderColor ?? Color.clear, lineWidth: style.borderColor != nil ? 1 : 0)
            )
            .clipShape(Capsule())
        }
        .disabled(isDisabled || isLoading)
    }
}

// MARK: - Responsive Media Frame Component

@available(iOS 17.0.0, *)
public struct ResponsiveMediaFrame<Content: View>: View {
    let content: Content
    let width: CGFloat
    let type: Responsive.MediaType
    let aspectRatio: CGFloat?
    
    public init(
        width: CGFloat,
        type: Responsive.MediaType,
        aspectRatio: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.width = width
        self.type = type
        self.aspectRatio = aspectRatio
        self.content = content()
    }
    
    public var body: some View {
        let height = aspectRatio != nil ? width / (aspectRatio ?? 1) : Responsive.mediaHeight(for: width, type: type)
        
        content
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: Responsive.isLargeScreen(width: width) ? 16 : 12))
    }
}

// MARK: - Responsive Icon Row Component

@available(iOS 17.0.0, *)
public struct ResponsiveIconRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let width: CGFloat
    let action: (() -> Void)?
    
    public init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        width: CGFloat,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.width = width
        self.action = action
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AroosiColors.primary)
                .frame(width: Responsive.iconWidth(for: width))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AroosiTypography.body(weight: .medium, width: width))
                    .foregroundStyle(AroosiColors.text)
                
                if let subtitle {
                    Text(subtitle)
                        .font(AroosiTypography.caption(width: width))
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
}

// MARK: - Responsive Stack Component

@available(iOS 17.0.0, *)
public struct ResponsiveVStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat?
    let width: CGFloat
    let content: Content
    
    public init(
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat? = nil,
        width: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.width = width
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: alignment, spacing: spacing ?? Responsive.spacing(width: width)) {
            content
        }
    }
}

@available(iOS 17.0.0, *)
public struct ResponsiveHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let width: CGFloat
    let content: Content
    
    public init(
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        width: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.width = width
        self.content = content()
    }
    
    public var body: some View {
        HStack(alignment: alignment, spacing: spacing ?? Responsive.spacing(width: width)) {
            content
        }
    }
}

// MARK: - View Extension for Conditional Modifiers

@available(iOS 17.0.0, *)
extension View {
    @ViewBuilder
    func applyIfLet<T>(_ value: T?, transform: (Self, T) -> some View) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

// MARK: - Responsive Grid Component

@available(iOS 17.0.0, *)
public struct ResponsiveGrid<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    let width: CGFloat
    let content: Content
    
    public init(
        columns: Int? = nil,
        spacing: CGFloat? = nil,
        width: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns ?? Responsive.gridColumns(width: width)
        self.spacing = spacing ?? Responsive.spacing(width: width)
        self.width = width
        self.content = content()
    }
    
    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            content
        }
    }
}

// MARK: - Responsive Container

@available(iOS 17.0.0, *)
public struct ResponsiveContainer<Content: View>: View {
    let content: Content
    let maxWidth: CGFloat?
    let alignment: Alignment
    let padding: EdgeInsets?
    
    public init(
        maxWidth: CGFloat? = nil,
        alignment: Alignment = .topLeading,
        padding: EdgeInsets? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        self.alignment = alignment
        self.padding = padding
        self.content = content()
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let responsivePadding = padding ?? Responsive.screenPadding(width: width)
            
            content
                .frame(maxWidth: maxWidth ?? .infinity, alignment: alignment)
                .padding(responsivePadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        }
    }
}
