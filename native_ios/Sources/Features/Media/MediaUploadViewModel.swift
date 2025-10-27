#if os(iOS)
import Foundation
import PhotosUI
import UIKit
import AVFoundation
import ImageIO

@available(iOS 17, *)
@MainActor
class MediaUploadViewModel: ObservableObject {
    @Published var state = MediaUploadState()
    
    private let mediaService: MediaService
    private let compressionService: ImageCompressionService
    private let permissionManager: PermissionManager
    
    init(mediaService: MediaService = DefaultMediaService(),
         compressionService: ImageCompressionService = DefaultImageCompressionService(),
         permissionManager: PermissionManager = .shared) {
        self.mediaService = mediaService
        self.compressionService = compressionService
        self.permissionManager = permissionManager
    }
    
    func processSelectedItems(_ items: [PhotosPickerItem]) {
        Task {
            // Check photo library permission first
            let hasPermission = await permissionManager.handlePhotoLibraryPermission()
            guard hasPermission else {
                state.errorMessage = "Photo library permission is required to select media"
                return
            }
            
            do {
                state.isUploading = true
                state.clearError()
                
                for item in items {
                    if let data = try await item.loadTransferable(type: Data.self) {
                        let processedData = try await compressionService.compressImageData(data, quality: 0.8)
                        let url = try await mediaService.uploadMedia(data: processedData, type: .image)
                        state.uploadedURLs.append(url)
                        
                        // Show success toast for first upload
                        if state.uploadedURLs.count == 1 {
                            ToastManager.shared.showSuccess("Photo uploaded successfully!")
                        }
                    }
                }
                
                state.selectedItems.removeAll()
                
            } catch {
                state.errorMessage = "Failed to process media: \(error.localizedDescription)"
            }
            state.isUploading = false
        }
    }
    
    func showCamera() async {
        let hasPermission = await permissionManager.handleCameraPermission()
        if hasPermission {
            // Present camera interface
            state.errorMessage = "Camera interface coming soon"
        } else {
            state.errorMessage = "Camera permission is required to take photos"
        }
    }
    
    func showVideoPicker() async {
        let hasPermission = await permissionManager.handlePhotoLibraryPermission()
        if hasPermission {
            // Present video picker
            state.errorMessage = "Video upload coming soon"
        } else {
            state.errorMessage = "Photo library permission is required to select videos"
        }
    }
    
    func removeMedia(at index: Int) {
        guard index < state.uploadedURLs.count else { return }
        
        Task {
            do {
                let url = state.uploadedURLs[index]
                try await mediaService.deleteMedia(url: url)
                state.uploadedURLs.remove(at: index)
            } catch {
                state.errorMessage = "Failed to remove media: \(error.localizedDescription)"
            }
        }
    }
    
    func clearError() {
        state.clearError()
    }
}

// MARK: - State

@available(iOS 17, *)
class MediaUploadState: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var uploadedURLs: [URL] = []
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var showingPhotoPicker = false
    
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - Protocols

protocol MediaService {
    func uploadMedia(data: Data, type: MediaType) async throws -> URL
    func deleteMedia(url: URL) async throws
}

protocol ImageCompressionService {
    func compressImageData(_ data: Data, quality: CGFloat) async throws -> Data
    func compressVideoData(_ url: URL) async throws -> URL
}

enum MediaType {
    case image
    case video
}

// MARK: - Default Implementations

class DefaultMediaService: MediaService {
    private let storageService: StorageService
    
    init(storageService: StorageService = DefaultStorageService()) {
        self.storageService = storageService
    }
    
    func uploadMedia(data: Data, type: MediaType) async throws -> URL {
        let fileName = generateFileName(for: type)
        let path = "media/\(fileName)"
        
        return try await storageService.uploadData(data, path: path)
    }
    
    func deleteMedia(url: URL) async throws {
        try await storageService.deleteFile(at: url)
    }
    
    private func generateFileName(for type: MediaType) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let uuid = UUID().uuidString.prefix(8)
        
        switch type {
        case .image:
            return "image_\(timestamp)_\(uuid).jpg"
        case .video:
            return "video_\(timestamp)_\(uuid).mp4"
        }
    }
}

class DefaultImageCompressionService: ImageCompressionService {
    func compressImageData(_ data: Data, quality: CGFloat) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let image = UIImage(data: data) else {
                    continuation.resume(throwing: MediaError.invalidImageData)
                    return
                }
                
                // Resize image if too large
                let resizedImage = self.resizeImageIfNeeded(image)
                
                // Compress image
                guard let compressedData = resizedImage.jpegData(compressionQuality: quality) else {
                    continuation.resume(throwing: MediaError.compressionFailed)
                    return
                }
                
                continuation.resume(returning: compressedData)
            }
        }
    }
    
    func compressVideoData(_ url: URL) async throws -> URL {
        logger.info("Starting video compression for: \(url.lastPathComponent)")
        
        return try await withCheckedThrowingContinuation { continuation in
            let asset = AVAsset(url: url)
            
            guard asset.isReadable else {
                continuation.resume(throwing: MediaError.compressionFailed)
                return
            }
            
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("compressed_\(UUID().uuidString).mp4")
            
            guard let exportSession = AVAssetExportSession(
                asset: asset,
                presetName: AVAssetExportPresetMediumQuality
            ) else {
                continuation.resume(throwing: MediaError.compressionFailed)
                return
            }
            
            exportSession.outputURL = outputURL
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true
            
            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    switch exportSession.status {
                    case .completed:
                        logger.info("Video compression completed successfully")
                        continuation.resume(returning: outputURL)
                    case .failed:
                        logger.error("Video compression failed: \(exportSession.error?.localizedDescription ?? "Unknown error")")
                        continuation.resume(throwing: MediaError.compressionFailed)
                    case .cancelled:
                        logger.info("Video compression was cancelled")
                        continuation.resume(throwing: MediaError.compressionFailed)
                    default:
                        continuation.resume(throwing: MediaError.compressionFailed)
                    }
                }
            }
        }
    }
    
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024
        
        if image.size.width <= maxDimension && image.size.height <= maxDimension {
            return image
        }
        
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
}

// MARK: - Storage Service

protocol StorageService {
    func uploadData(_ data: Data, path: String) async throws -> URL
    func deleteFile(at url: URL) async throws
}

class DefaultStorageService: StorageService {
    private let storage = Storage.storage()
    private let logger = Logger.shared
    
    func uploadData(_ data: Data, path: String) async throws -> URL {
        logger.info("Uploading data to Firebase Storage: \(path)")
        
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = contentType(for: path)
        
        do {
            let _ = try await storageRef.putDataAsync(data, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            
            logger.info("Successfully uploaded file to: \(downloadURL.absoluteString)")
            return downloadURL
            
        } catch {
            logger.error("Failed to upload file: \(error.localizedDescription)")
            throw MediaError.uploadFailed
        }
    }
    
    func deleteFile(at url: URL) async throws {
        logger.info("Deleting file from Firebase Storage: \(url.absoluteString)")
        
        do {
            let storageRef = Storage.storage().reference(forURL: url.absoluteString)
            try await storageRef.delete()
            
            logger.info("Successfully deleted file: \(url.absoluteString)")
            
        } catch {
            logger.error("Failed to delete file: \(error.localizedDescription)")
            throw MediaError.uploadFailed
        }
    }
    
    private func contentType(for path: String) -> String {
        let ext = URL(fileURLWithPath: path).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        default:
            return "application/octet-stream"
        }
    }
}

// MARK: - Errors

enum MediaError: Error {
    case invalidImageData
    case compressionFailed
    case uploadFailed
    case fileSizeExceeded
    case unsupportedFormat
    
    var localizedDescription: String {
        switch self {
        case .invalidImageData:
            return "The selected image is invalid or corrupted"
        case .compressionFailed:
            return "Failed to compress the image"
        case .uploadFailed:
            return "Failed to upload the media"
        case .fileSizeExceeded:
            return "The file size exceeds the maximum allowed limit"
        case .unsupportedFormat:
            return "The file format is not supported"
        }
    }
}

// MARK: - Extensions

extension Data: @retroactive Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .image)
        DataRepresentation(contentType: .video)
    }
}

extension PhotosPickerItem {
    func loadImageData() async throws -> Data {
        return try await self.loadTransferable(type: Data.self) ?? Data()
    }
}

// MARK: - Image Processing Utilities

class ImageProcessingUtilities {
    static func validateImageSize(_ data: Data, maxSize: Int = 10 * 1024 * 1024) throws {
        guard data.count <= maxSize else {
            throw MediaError.fileSizeExceeded
        }
    }
    
    static func validateImageFormat(_ data: Data) throws {
        guard let image = UIImage(data: data) else {
            throw MediaError.unsupportedFormat
        }
    }
    
    static func generateThumbnail(from videoURL: URL, at time: TimeInterval = 1.0) async throws -> UIImage {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: time, preferredTimescale: 600), actualTime: nil)
        return UIImage(cgImage: cgImage)
    }
}

#endif
