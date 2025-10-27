#if canImport(UIKit)
import AVFoundation
import CoreLocation
import Foundation
import Photos
import UserNotifications
#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

@available(iOS 17, *)
public enum PermissionType: Equatable {
    case camera
    case microphone
    case photoLibrary
    case photoLibraryAddOnly
    case tracking
    case notifications
    case locationWhenInUse
}

@available(iOS 17, *)
public enum PermissionStatus: Equatable {
    case notDetermined
    case denied
    case restricted
    case authorized
    case limited
}

@available(iOS 17, *)
public protocol PermissionServicing {
    func status(for type: PermissionType) async -> PermissionStatus
    func request(_ type: PermissionType) async -> PermissionStatus
}

@available(iOS 17, *)
public final class DefaultPermissionService: NSObject, PermissionServicing {
    private let locationRequester = LocationPermissionRequester()

    public override init() {
        super.init()
    }

    public func status(for type: PermissionType) async -> PermissionStatus {
        switch type {
        case .camera:
            return PermissionStatusMapper.map(AVCaptureDevice.authorizationStatus(for: .video))
        case .microphone:
            return PermissionStatusMapper.map(AVAudioSession.sharedInstance().recordPermission)
        case .photoLibrary:
            return PermissionStatusMapper.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
        case .photoLibraryAddOnly:
            return PermissionStatusMapper.map(PHPhotoLibrary.authorizationStatus(for: .addOnly))
        case .tracking:
            #if canImport(AppTrackingTransparency)
            if #available(iOS 14.5, *) {
                return PermissionStatusMapper.map(ATTrackingManager.trackingAuthorizationStatus)
            } else {
                return .authorized
            }
            #else
            return .authorized
            #endif
        case .notifications:
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return PermissionStatusMapper.map(settings.authorizationStatus)
        case .locationWhenInUse:
            return PermissionStatusMapper.map(CLLocationManager().authorizationStatus)
        }
    }

    public func request(_ type: PermissionType) async -> PermissionStatus {
        switch type {
        case .camera:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .authorized : .denied
        case .microphone:
            return await requestMicrophone()
        case .photoLibrary:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return PermissionStatusMapper.map(status)
        case .photoLibraryAddOnly:
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return PermissionStatusMapper.map(status)
        case .tracking:
            #if canImport(AppTrackingTransparency)
            if #available(iOS 14.5, *) {
                let status = await ATTrackingManager.requestTrackingAuthorization()
                return PermissionStatusMapper.map(status)
            } else {
                return .authorized
            }
            #else
            return .authorized
            #endif
        case .notifications:
            return await requestNotifications()
        case .locationWhenInUse:
            return await locationRequester.requestWhenInUseAuthorization()
        }
    }

    private func requestMicrophone() async -> PermissionStatus {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted ? .authorized : .denied)
            }
        }
    }

    private func requestNotifications() async -> PermissionStatus {
        let center = UNUserNotificationCenter.current()
        let currentSettings = await center.notificationSettings()
        switch currentSettings.authorizationStatus {
        case .notDetermined:
            let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted == true {
                let refreshed = await center.notificationSettings()
                return PermissionStatusMapper.map(refreshed.authorizationStatus)
            }
            return .denied
        default:
            return PermissionStatusMapper.map(currentSettings.authorizationStatus)
        }
    }
}

@available(iOS 17, *)
private enum PermissionStatusMapper {
    static func map(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    static func map(_ status: AVAudioSession.RecordPermission) -> PermissionStatus {
        switch status {
        case .granted:
            return .authorized
        case .denied:
            return .denied
        case .undetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    static func map(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .limited:
            return status == .limited ? .limited : .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        @unknown default:
            return .notDetermined
        }
    }

    #if canImport(AppTrackingTransparency)
    static func map(_ status: ATTrackingManager.AuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
    #endif

    static func map(_ status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .provisional, .ephemeral:
            return .authorized
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }

    static func map(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .notDetermined
        }
    }
}

@available(iOS 17, *)
private final class LocationPermissionRequester: NSObject, CLLocationManagerDelegate {
    private let locationManager: CLLocationManager
    private var continuation: CheckedContinuation<PermissionStatus, Never>?

    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
    }

    func requestWhenInUseAuthorization() async -> PermissionStatus {
        let currentStatus = PermissionStatusMapper.map(locationManager.authorizationStatus)
        if currentStatus != .notDetermined {
            return currentStatus
        }

        return await withCheckedContinuation { continuation in
            self.continuation?.resume(returning: .notDetermined)
            self.continuation = continuation
            DispatchQueue.main.async {
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let continuation else { return }
        let status = PermissionStatusMapper.map(manager.authorizationStatus)
        if status == .notDetermined { return }
        continuation.resume(returning: status)
        self.continuation = nil
    }
}

#endif
