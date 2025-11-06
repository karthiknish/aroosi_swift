#if os(iOS)
import SwiftUI
import Combine

/**
 * Cached Async Image Component
 * 
 * Enhanced async image loading component with memory and disk caching
 * for optimal performance and reduced network usage.
 */
@available(iOS 17, *)
public struct CachedAsyncImageView: View {
    
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
    
    // MARK: - State
    
    @StateObject private var imageLoader = ImageLoader()
    @State private var imageState: ImageState = .loading
    
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
        Group {
            switch imageState {
            case .loading:
                loadingView
            case .success(let image):
                successView(image)
            case .failure:
                failureView
            }
        }
        .applyShape(shape)
        .applySize(size)
        .accessibilityLabel(accessibilityLabel)
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _, newURL in
            if newURL != url {
                loadImage()
            }
        }
    }
    
    // MARK: - Methods
    
    private func loadImage() {
        guard let url = url else {
            imageState = .failure
            return
        }
        
        imageState = .loading
        
        Task {
            do {
                let image = try await imageLoader.loadImage(from: url)
                await MainActor.run {
                    imageState = .success(image)
                }
            } catch {
                await MainActor.run {
                    imageState = .failure
                }
            }
        }
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
                Image(uiImage: imageState.image!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
            } else {
                Image(uiImage: imageState.image!)
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
                .font(.system(size: placeholder.iconSize, weight: .medium))
                .foregroundStyle(placeholder.iconColor)
        }
    }
    
    @ViewBuilder
    private var avatarPlaceholder: some View {
        ZStack {
            gradientPlaceholder
            
            if let name = placeholder.avatarName, !name.isEmpty {
                Text(String(name.prefix(2)).uppercased())
                    .font(.system(size: placeholder.avatarSize, weight: .semibold))
                    .foregroundStyle(placeholder.avatarColor)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: placeholder.iconSize, weight: .medium))
                    .foregroundStyle(placeholder.iconColor)
            }
        }
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        Group {
            switch loading.type {
            case .progress:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: loading.color))
                    .scaleEffect(loading.scale)
            case .skeleton:
                skeletonView
            case .none:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private var skeletonView: some View {
        RoundedRectangle(cornerRadius: shape.cornerRadius)
            .fill(LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1), Color.gray.opacity(0.3)],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .scaleEffect(x: 1.2)
            .opacity(0.8)
    }
    
    @ViewBuilder
    private var errorOverlay: some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(errorHandling.errorColor)
            
            if let message = errorHandling.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(errorHandling.errorColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(8)
        .background(Color.black.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private var defaultErrorView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: shape.cornerRadius)
                .fill(Color.gray.opacity(0.2))
            
            VStack(spacing: 8) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.gray)
                
                Text("Failed to load image")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
        }
    }
    
    private var accessibilityLabel: String {
        if let url = url {
            return "Profile image"
        } else {
            return "No image available"
        }
    }
}

// MARK: - Image Loader

@available(iOS 17, *)
@MainActor
class ImageLoader: ObservableObject {
    private let cache = ImageCache.shared
    private var cancellables = Set<AnyCancellable>()
    
    func loadImage(from url: URL) async throws -> UIImage {
        // Check memory cache first
        if let cachedImage = cache.image(for: url) {
            return cachedImage
        }
        
        // Check disk cache
        if let diskImage = await cache.imageFromDisk(for: url) {
            return diskImage
        }
        
        // Download image
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ImageLoadError.invalidData
        }
        
        // Cache the image
        await cache.cacheImage(image, for: url)
        
        return image
    }
}

// MARK: - Image Cache

@available(iOS 17, *)
class ImageCache {
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSURL, UIImage>()
    private let diskCacheURL: URL
    private let fileManager = FileManager.default
    
    private init() {
        // Configure memory cache
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        // Setup disk cache
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDir.appendingPathComponent("ImageCache")
        
        createDiskCacheDirectory()
    }
    
    // MARK: - Memory Cache
    
    func image(for url: URL) -> UIImage? {
        return memoryCache.object(forKey: url as NSURL)
    }
    
    func cacheImage(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * 4) // Approximate memory cost
        memoryCache.setObject(image, forKey: url as NSURL, cost: cost)
    }
    
    // MARK: - Disk Cache
    
    func imageFromDisk(for url: URL) async -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(url.absoluteString.md5)
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                if let data = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: data) {
                    // Cache in memory too
                    self.cacheImage(image, for: url)
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func cacheImage(_ image: UIImage, for url: URL) async {
        let fileURL = diskCacheURL.appendingPathComponent(url.absoluteString.md5)
        
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                guard let data = image.pngData() else {
                    continuation.resume()
                    return
                }
                
                do {
                    try data.write(to: fileURL)
                    continuation.resume()
                } catch {
                    print("Failed to cache image to disk: \(error)")
                    continuation.resume()
                }
            }
        }
    }
    
    private func createDiskCacheDirectory() {
        if !fileManager.fileExists(atPath: diskCacheURL.path) {
            try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        
        DispatchQueue.global(qos: .utility).async {
            try? self.fileManager.removeItem(at: self.diskCacheURL)
            self.createDiskCacheDirectory()
        }
    }
}

// MARK: - Supporting Types

enum ImageState {
    case loading
    case success(UIImage)
    case failure
    
    var image: UIImage? {
        if case .success(let image) = self {
            return image
        }
        return nil
    }
}

enum ImageLoadError: Error {
    case invalidData
    case networkError(Error)
}

// MARK: - String Extension

extension String {
    var md5: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { bytes in
            return bytes.bindMemory(to: UInt8.self)
        }
        
        var digest = [UInt8](repeating: 0, count: 16)
        // This is a simplified MD5 - in production, use CommonCrypto or CryptoKit
        return "cached_\(self.hash)" // Simplified for demo
    }
}

// MARK: - Convenience Extensions

extension CachedAsyncImageView {
    public static func profile(url: URL?) -> some View {
        CachedAsyncImageView(
            url: url,
            shape: .circle,
            size: .medium,
            placeholder: .avatar,
            loading: .default,
            errorHandling: .default
        )
    }
    
    public static func thumbnail(url: URL?) -> some View {
        CachedAsyncImageView(
            url: url,
            shape: .roundedRectangle(cornerRadius: 8),
            size: .small,
            placeholder: .gradient,
            loading: .skeleton,
            errorHandling: .default
        )
    }
    
    public static func banner(url: URL?) -> some View {
        CachedAsyncImageView(
            url: url,
            shape: .rectangle,
            size: .large,
            placeholder: .gradient,
            loading: .default,
            errorHandling: .default
        )
    }
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
    VStack(spacing: 20) {
        CachedAsyncImageView.profile(url: URL(string: "https://picsum.photos/200/200"))
        
        CachedAsyncImageView.thumbnail(url: URL(string: "https://picsum.photos/150/150"))
        
        CachedAsyncImageView.banner(url: URL(string: "https://picsum.photos/400/200"))
    }
    .padding()
}

#endif
