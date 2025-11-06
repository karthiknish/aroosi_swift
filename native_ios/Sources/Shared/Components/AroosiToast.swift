import SwiftUI
#if os(iOS)

// MARK: - Toast System

@available(iOS 17.0.0, *)
public struct AroosiToast: View {
    let message: String
    let style: ToastStyle
    let onDismiss: (() -> Void)?
    
    @State private var isVisible = false
    
    public init(message: String, style: ToastStyle = .info, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.style = style
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: style.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(style.iconColor)
            
            Text(message)
                .font(AroosiTypography.caption(weight: .medium))
                .foregroundStyle(style.textColor)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if onDismiss != nil {
                Button(action: {
                    withAnimation(.easeOut(duration: AroosiMotionDurations.fast)) {
                        isVisible = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + AroosiMotionDurations.fast) {
                        onDismiss?()
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(style.iconColor.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(style.backgroundColor)
                .shadow(color: style.backgroundColor.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(style.borderColor.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Toast Styles

@available(iOS 17.0.0, *)
public enum ToastStyle {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success:
            return AroosiColors.success.opacity(0.95)
        case .error:
            return AroosiColors.error.opacity(0.95)
        case .warning:
            return AroosiColors.warning.opacity(0.95)
        case .info:
            return AroosiColors.primary.opacity(0.95)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .success:
            return AroosiColors.success
        case .error:
            return AroosiColors.error
        case .warning:
            return AroosiColors.warning
        case .info:
            return AroosiColors.primary
        }
    }
    
    var iconColor: Color {
        switch self {
        case .success:
            return .white
        case .error:
            return .white
        case .warning:
            return .white
        case .info:
            return .white
        }
    }
    
    var textColor: Color {
        return .white
    }
}

// MARK: - Toast Manager

@available(iOS 17.0.0, *)
public class ToastManager: ObservableObject {
    @Published public var currentToast: ToastItem?
    
    public static let shared = ToastManager()
    
    private init() {}
    
    public func show(message: String, style: ToastStyle = .info, duration: Double = 3.0) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentToast = ToastItem(message: message, style: style, duration: duration)
        }
        
        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if self.currentToast?.message == message {
                self.dismiss()
            }
        }
    }
    
    public func showSuccess(_ message: String, duration: Double = 3.0) {
        show(message: message, style: .success, duration: duration)
    }
    
    public func showError(_ message: String, duration: Double = 4.0) {
        show(message: message, style: .error, duration: duration)
    }
    
    public func showWarning(_ message: String, duration: Double = 3.5) {
        show(message: message, style: .warning, duration: duration)
    }
    
    public func showInfo(_ message: String, duration: Double = 3.0) {
        show(message: message, style: .info, duration: duration)
    }
    
    public func dismiss() {
        withAnimation(.easeOut(duration: AroosiMotionDurations.fast)) {
            currentToast = nil
        }
    }
}

// MARK: - Toast Item

@available(iOS 17.0.0, *)
public struct ToastItem: Identifiable, Equatable {
    public let id = UUID()
    public let message: String
    public let style: ToastStyle
    public let duration: Double
    
    public init(message: String, style: ToastStyle, duration: Double) {
        self.message = message
        self.style = style
        self.duration = duration
    }
    
    public static func == (lhs: ToastItem, rhs: ToastItem) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Toast Container View

@available(iOS 17.0.0, *)
public struct ToastContainer: View {
    @StateObject private var toastManager = ToastManager.shared
    
    public init() {}
    
    public var body: some View {
        VStack {
            Spacer()
            
            if let toast = toastManager.currentToast {
                AroosiToast(
                    message: toast.message,
                    style: toast.style,
                    onDismiss: {
                        toastManager.dismiss()
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: AroosiMotionDurations.medium), value: toastManager.currentToast?.id)
    }
}

// MARK: - View Extensions

@available(iOS 17.0.0, *)
public extension View {
    func toastContainer() -> some View {
        self.overlay(alignment: .bottom) {
            ToastContainer()
        }
    }
}

// MARK: - Convenience Banner Components

@available(iOS 17.0.0, *)
public struct SuccessBanner: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    public init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        AroosiToast(message: message, style: .success, onDismiss: onDismiss)
    }
}

@available(iOS 17.0.0, *)
public struct ErrorBanner: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    public init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        AroosiToast(message: message, style: .error, onDismiss: onDismiss)
    }
}

@available(iOS 17.0.0, *)
public struct WarningBanner: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    public init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        AroosiToast(message: message, style: .warning, onDismiss: onDismiss)
    }
}

@available(iOS 17.0.0, *)
public struct InfoBanner: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    public init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        AroosiToast(message: message, style: .info, onDismiss: onDismiss)
    }
}

// MARK: - Legacy Message Banner (for backward compatibility)

@available(iOS 17.0.0, *)
public struct MessageBanner: View {
    let message: String
    let style: BannerStyle
    
    public init(message: String, style: BannerStyle) {
        self.message = message
        self.style = style
    }
    
    public var body: some View {
        AroosiToast(
            message: message,
            style: style.toastStyle,
            onDismiss: {
                ToastManager.shared.dismiss()
            }
        )
    }
}

@available(iOS 17.0.0, *)
public enum BannerStyle {
    case success
    case error
    case info
    case warning
    
    var toastStyle: ToastStyle {
        switch self {
        case .success:
            return .success
        case .error:
            return .error
        case .info:
            return .info
        case .warning:
            return .warning
        }
    }
}

// MARK: - Banner Component (for backward compatibility)

@available(iOS 17.0.0, *)
public struct Banner: View {
    let message: String
    let style: BannerStyle
    let onDismiss: (() -> Void)?
    
    public init(message: String, style: BannerStyle, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.style = style
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        AroosiToast(message: message, style: style.toastStyle, onDismiss: onDismiss)
    }
}

// MARK: - Inline Message View (for backward compatibility)

@available(iOS 17.0.0, *)
public struct InlineMessageView: View {
    let message: String
    let style: BannerStyle
    
    public init(message: String, style: BannerStyle) {
        self.message = message
        self.style = style
    }
    
    public var body: some View {
        AroosiToast(message: message, style: style.toastStyle)
    }
}

#endif
