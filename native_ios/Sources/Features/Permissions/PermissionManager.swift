#if os(iOS)
import SwiftUI
import AVFoundation
import CoreLocation
import Photos
import UserNotifications

@available(iOS 17, *)
class PermissionManager: ObservableObject {
    static let shared = PermissionManager()
    
    @Published var permissionStatuses: [PermissionType: PermissionStatus] = [:]
    @Published var showingPermissionAlert = false
    @Published var currentPermissionRequest: PermissionRequest?
    
    private let permissionService: PermissionServicing
    
    init(permissionService: PermissionServicing = DefaultPermissionService()) {
        self.permissionService = permissionService
    }
    
    // MARK: - Permission Status Checking
    
    func checkPermissionStatus(for type: PermissionType) async -> PermissionStatus {
        let status = await permissionService.status(for: type)
        
        await MainActor.run {
            permissionStatuses[type] = status
        }
        
        return status
    }
    
    func checkAllPermissions() async {
        await withTaskGroup(of: Void.self) { group in
            for permissionType in PermissionType.allCases {
                group.addTask {
                    await self.checkPermissionStatus(for: permissionType)
                }
            }
        }
    }
    
    // MARK: - Permission Requesting
    
    func requestPermission(_ type: PermissionType) async -> PermissionStatus {
        let status = await permissionService.request(type)
        
        await MainActor.run {
            permissionStatuses[type] = status
            
            if status == .denied || status == .restricted {
                currentPermissionRequest = PermissionRequest(type: type, status: status)
                showingPermissionAlert = true
            }
        }
        
        return status
    }
    
    func requestPermissionWithRationale(_ type: PermissionType, rationale: String) async -> PermissionStatus {
        // Show rationale before requesting permission
        await showPermissionRationale(for: type, message: rationale)
        
        return await requestPermission(type)
    }
    
    // MARK: - Permission Validation
    
    func isPermissionGranted(_ type: PermissionType) -> Bool {
        guard let status = permissionStatuses[type] else { return false }
        return status == .authorized || status == .limited
    }
    
    func requiresPermissionRequest(_ type: PermissionType) -> Bool {
        guard let status = permissionStatuses[type] else { return true }
        return status == .notDetermined
    }
    
    func isPermissionDenied(_ type: PermissionType) -> Bool {
        guard let status = permissionStatuses[type] else { return false }
        return status == .denied || status == .restricted
    }
    
    // MARK: - Permission Handlers for Features
    
    func handleCameraPermission() async -> Bool {
        let status = await checkPermissionStatus(for: .camera)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            let newStatus = await requestPermission(.camera)
            return newStatus == .authorized
        case .denied, .restricted:
            await showSettingsRedirect(for: .camera)
            return false
        case .limited:
            return true
        }
    }
    
    func handleMicrophonePermission() async -> Bool {
        let status = await checkPermissionStatus(for: .microphone)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            let newStatus = await requestPermission(.microphone)
            return newStatus == .authorized
        case .denied, .restricted:
            await showSettingsRedirect(for: .microphone)
            return false
        case .limited:
            return true
        }
    }
    
    func handlePhotoLibraryPermission() async -> Bool {
        let status = await checkPermissionStatus(for: .photoLibrary)
        
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await requestPermission(.photoLibrary)
            return newStatus == .authorized || newStatus == .limited
        case .denied, .restricted:
            await showSettingsRedirect(for: .photoLibrary)
            return false
        }
    }
    
    func handleLocationPermission() async -> Bool {
        let status = await checkPermissionStatus(for: .locationWhenInUse)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            let newStatus = await requestPermission(.locationWhenInUse)
            return newStatus == .authorized
        case .denied, .restricted:
            await showSettingsRedirect(for: .locationWhenInUse)
            return false
        case .limited:
            return true
        }
    }
    
    func handleNotificationPermission() async -> Bool {
        let status = await checkPermissionStatus(for: .notifications)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            let newStatus = await requestPermission(.notifications)
            return newStatus == .authorized
        case .denied, .restricted:
            await showSettingsRedirect(for: .notifications)
            return false
        case .limited:
            return true
        }
    }
    
    // MARK: - UI Helpers
    
    private func showPermissionRationale(for type: PermissionType, message: String) async {
        await MainActor.run {
            // This would show a custom rationale view
            print("Showing rationale for \(type): \(message)")
        }
    }
    
    private func showSettingsRedirect(for type: PermissionType) async {
        await MainActor.run {
            currentPermissionRequest = PermissionRequest(
                type: type,
                status: .denied,
                requiresSettingsRedirect: true
            )
            showingPermissionAlert = true
        }
    }
    
    func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
    }
    
    func dismissPermissionAlert() {
        showingPermissionAlert = false
        currentPermissionRequest = nil
    }
}

// MARK: - Permission Request Model

struct PermissionRequest: Identifiable {
    let id = UUID()
    let type: PermissionType
    let status: PermissionStatus
    let requiresSettingsRedirect: Bool
    
    init(type: PermissionType, status: PermissionStatus, requiresSettingsRedirect: Bool = false) {
        self.type = type
        self.status = status
        self.requiresSettingsRedirect = requiresSettingsRedirect
    }
    
    var title: String {
        switch type {
        case .camera:
            return "Camera Access Required"
        case .microphone:
            return "Microphone Access Required"
        case .photoLibrary:
            return "Photo Library Access Required"
        case .photoLibraryAddOnly:
            return "Photo Library Access Required"
        case .tracking:
            return "Tracking Permission Required"
        case .notifications:
            return "Notification Permission Required"
        case .locationWhenInUse:
            return "Location Access Required"
        }
    }
    
    var message: String {
        if requiresSettingsRedirect {
            return "Please enable \(type.displayName) in Settings to use this feature."
        }
        
        switch type {
        case .camera:
            return "Aroosi needs camera access to capture profile photos and videos."
        case .microphone:
            return "Aroosi needs microphone access to record voice messages and audio."
        case .photoLibrary:
            return "Aroosi needs photo library access to let you select and share photos."
        case .photoLibraryAddOnly:
            return "Aroosi needs photo library access to save edited media."
        case .tracking:
            return "Aroosi uses tracking to personalize your experience and measure engagement."
        case .notifications:
            return "Enable notifications to stay updated with messages and matches."
        case .locationWhenInUse:
            return "Aroosi uses your location to find nearby matches and relevant events."
        }
    }
    
    var settingsAction: String {
        return "Open Settings"
    }
}

// MARK: - PermissionType Extensions

extension PermissionType: CaseIterable, Identifiable {
    public var id: String { rawValue }
    
    public var rawValue: String {
        switch self {
        case .camera:
            return "camera"
        case .microphone:
            return "microphone"
        case .photoLibrary:
            return "photoLibrary"
        case .photoLibraryAddOnly:
            return "photoLibraryAddOnly"
        case .tracking:
            return "tracking"
        case .notifications:
            return "notifications"
        case .locationWhenInUse:
            return "locationWhenInUse"
        }
    }
    
    public var displayName: String {
        switch self {
        case .camera:
            return "Camera"
        case .microphone:
            return "Microphone"
        case .photoLibrary:
            return "Photo Library"
        case .photoLibraryAddOnly:
            return "Photo Library"
        case .tracking:
            return "App Tracking"
        case .notifications:
            return "Notifications"
        case .locationWhenInUse:
            return "Location"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .camera:
            return "camera"
        case .microphone:
            return "mic"
        case .photoLibrary:
            return "photo"
        case .photoLibraryAddOnly:
            return "photo.badge.plus"
        case .tracking:
            return "person.crop.circle.badge.questionmark"
        case .notifications:
            return "bell"
        case .locationWhenInUse:
            return "location"
        }
    }
    
    public var description: String {
        switch self {
        case .camera:
            return "Access camera for photos and videos"
        case .microphone:
            return "Access microphone for voice messages"
        case .photoLibrary:
            return "Access photo library for media selection"
        case .photoLibraryAddOnly:
            return "Save media to photo library"
        case .tracking:
            return "Personalize ads and measure engagement"
        case .notifications:
            return "Receive push notifications"
        case .locationWhenInUse:
            return "Find nearby matches and events"
        }
    }
}

// MARK: - Permission Status Extensions

extension PermissionStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined:
            return "Not Requested"
        case .denied:
            return "Denied"
        case .restricted:
            return "Restricted"
        case .authorized:
            return "Authorized"
        case .limited:
            return "Limited Access"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .notDetermined:
            return "questionmark.circle"
        case .denied:
            return "xmark.circle.fill"
        case .restricted:
            return "lock.circle.fill"
        case .authorized:
            return "checkmark.circle.fill"
        case .limited:
            return "minus.circle.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .notDetermined:
            return .orange
        case .denied, .restricted:
            return .red
        case .authorized:
            return .green
        case .limited:
            return .yellow
        }
    }
}

// MARK: - Permission Alert View

@available(iOS 17, *)
struct PermissionAlertView: View {
    @ObservedObject var permissionManager: PermissionManager
    
    var body: some View {
        if let request = permissionManager.currentPermissionRequest {
            VStack(spacing: 20) {
                Image(systemName: request.type.systemImage)
                    .font(.system(size: 50))
                    .foregroundStyle(request.status.color)
                
                VStack(spacing: 8) {
                    Text(request.title)
                        .font(AroosiTypography.heading(.h3))
                        .multilineTextAlignment(.center)
                    
                    Text(request.message)
                        .font(AroosiTypography.body())
                        .foregroundStyle(AroosiColors.muted)
                        .multilineTextAlignment(.center)
                }
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        permissionManager.dismissPermissionAlert()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AroosiColors.cardBackground)
                    .foregroundStyle(AroosiColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    if request.requiresSettingsRedirect {
                        Button(request.settingsAction) {
                            permissionManager.openAppSettings()
                            permissionManager.dismissPermissionAlert()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AroosiColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(24)
            .background(AroosiColors.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 10)
        }
    }
}

#endif
