import Foundation

/// Mirrors the environment switching used in aroosi_flutter so both apps hit
/// the same backend tiers by default.
@available(iOS 17.0, *)
public class FlutterEnvironmentConfig: ObservableObject {
    
    public static let shared = FlutterEnvironmentConfig()
    
    private init() {}
    
    // MARK: - Environment Constants (from Flutter env.dart)
    
    private static let defaultDevBase = "http://localhost:3000/api"
    private static let defaultStagingBase = "https://staging.aroosi.app/api"
    private static let defaultProdBase = "https://www.aroosi.app/api"
    
    // MARK: - Environment Properties
    
    /// Current environment: development, staging, or production
    public var environment: String {
        let value = read("ENVIRONMENT")
        switch value.lowercased() {
        case "development", "dev":
            return "development"
        case "staging":
            return "staging"
        case "production", "prod":
        default:
            return "production"
        }
    }
    
    /// API base URL with environment-based defaults
    public var apiBaseUrl: String {
        let override = read("API_BASE_URL")
        if !override.isEmpty {
            return normalizeBase(override)
        }
        
        switch environment {
        case "development":
            return Self.defaultDevBase
        case "staging":
            return Self.defaultStagingBase
        case "production":
        default:
            return Self.defaultProdBase
        }
    }
    
    /// Firebase Storage bucket, overridable via env (FIREBASE_STORAGE_BUCKET).
    /// Falls back to the bucket configured in Firebase options.
    public var storageBucket: String {
        let override = read("FIREBASE_STORAGE_BUCKET").trimmingCharacters(in: .whitespacesAndNewlines)
        if !override.isEmpty { return override }
        
        // Fallback to Firebase project configuration
        return "aroosi-ios.firebasestorage.app"
    }
    
    // MARK: - Firebase Configuration (aligned with Flutter)
    
    /// Firebase project ID (matches Flutter configuration)
    public var firebaseProjectId: String {
        let override = read("FIREBASE_IOS_PROJECT_ID")
        return override.isEmpty ? "aroosi-ios" : override
    }
    
    /// Firebase iOS bundle ID (matches Flutter configuration)
    public var firebaseBundleId: String {
        let override = read("FIREBASE_IOS_BUNDLE_ID")
        return override.isEmpty ? "com.aroosi.mobile" : override
    }
    
    /// Firebase measurement ID (matches Flutter configuration)
    public var firebaseMeasurementId: String {
        let override = read("FIREBASE_IOS_MEASUREMENT_ID")
        return override.isEmpty ? "G-LW4V9JBD39" : override
    }
    
    /// Firebase iOS Google App ID
    public var firebaseGoogleAppId: String {
        let override = read("FIREBASE_IOS_GOOGLE_APP_ID")
        return override.isEmpty ? "1:320943801797:ios:9698384f0913adeaf6b7ac" : override
    }
    
    /// Firebase iOS Client ID
    public var firebaseClientId: String {
        let override = read("FIREBASE_IOS_CLIENT_ID")
        return override.isEmpty ? "762041256503-uc9qopr13761ictkgj53ba4gomtkvbha.apps.googleusercontent.com" : override
    }
    
    /// Firebase iOS API Key
    public var firebaseApiKey: String {
        let override = read("FIREBASE_IOS_API_KEY")
        return override.isEmpty ? "AIzaSyDBO0qloVCqP7su4WnBL72yUkH7KooGyzY" : override
    }
    
    /// Firebase iOS GCM Sender ID
    public var firebaseGcmSenderId: String {
        let override = read("FIREBASE_IOS_GCM_SENDER_ID")
        return override.isEmpty ? "320943801797" : override
    }
    
    /// GoogleService-Info.plist base64 encoded data
    public var googleServiceInfoPlistBase64: String {
        let override = read("GOOGLESERVICE_INFO_PLIST_BASE64")
        return override.isEmpty ? "" : override
    }
    
    /// iOS Profile base64 encoded data
    public var iosProfileBase64: String {
        let override = read("IOS_PROFILE_BASE64")
        return override.isEmpty ? "" : override
    }
    
    /// iOS Certificate base64 encoded data
    public var iosCertBase64: String {
        let override = read("IOS_CERT_BASE64")
        return override.isEmpty ? "" : override
    }
    
    /// iOS Certificate password
    public var iosCertPassword: String {
        let override = read("IOS_CERT_PASSWORD")
        return override.isEmpty ? "" : override
    }
    
    // MARK: - Private Methods
    
    private func read(_ key: String) -> String {
        // Try to read from environment variables first
        if let value = ProcessInfo.processInfo.environment[key], !value.isEmpty {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Fallback to Info.plist for build-time configuration
        if let value = Bundle.main.infoDictionary?[key] as? String, !value.isEmpty {
            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return ""
    }
    
    private func normalizeBase(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return trimmed }
        
        return trimmed.hasSuffix("/") 
            ? String(trimmed.dropLast())
            : trimmed
    }
    
    // MARK: - Debug Methods
    
    /// Print current environment configuration for debugging
    public func debugPrintConfiguration() {
        print("=== Flutter Environment Configuration ===")
        print("Environment: \(environment)")
        print("API Base URL: \(apiBaseUrl)")
        print("Storage Bucket: \(storageBucket)")
        print("Firebase Project ID: \(firebaseProjectId)")
        print("Firebase Bundle ID: \(firebaseBundleId)")
        print("Firebase Measurement ID: \(firebaseMeasurementId)")
        print("Firebase Google App ID: \(firebaseGoogleAppId)")
        print("Firebase Client ID: \(firebaseClientId)")
        print("Firebase API Key: \(firebaseApiKey)")
        print("Firebase GCM Sender ID: \(firebaseGcmSenderId)")
        print("GoogleService-Info.plist available: \(!googleServiceInfoPlistBase64.isEmpty)")
        print("iOS Profile available: \(!iosProfileBase64.isEmpty)")
        print("iOS Certificate available: \(!iosCertBase64.isEmpty)")
        print("==========================================")
    }
    
    // MARK: - Validation
    
    /// Validate that required environment variables are set
    public func validateConfiguration() -> [String] {
        var errors: [String] = []
        
        if read("ENVIRONMENT").isEmpty {
            errors.append("ENVIRONMENT is not set")
        }
        
        if storageBucket.isEmpty {
            errors.append("FIREBASE_STORAGE_BUCKET is not set")
        }
        
        if firebaseProjectId.isEmpty {
            errors.append("FIREBASE_IOS_PROJECT_ID is not set")
        }
        
        if firebaseGoogleAppId.isEmpty {
            errors.append("FIREBASE_IOS_GOOGLE_APP_ID is not set")
        }
        
        if firebaseClientId.isEmpty {
            errors.append("FIREBASE_IOS_CLIENT_ID is not set")
        }
        
        if firebaseApiKey.isEmpty || firebaseApiKey == "your_firebase_api_key_here" {
            errors.append("FIREBASE_IOS_API_KEY is not set or is using placeholder value")
        }
        
        if firebaseGcmSenderId.isEmpty {
            errors.append("FIREBASE_IOS_GCM_SENDER_ID is not set")
        }
        
        if googleServiceInfoPlistBase64.isEmpty {
            errors.append("GOOGLESERVICE_INFO_PLIST_BASE64 is not set")
        }
        
        if iosProfileBase64.isEmpty {
            errors.append("IOS_PROFILE_BASE64 is not set")
        }
        
        if iosCertBase64.isEmpty {
            errors.append("IOS_CERT_BASE64 is not set")
        }
        
        if iosCertPassword.isEmpty {
            errors.append("IOS_CERT_PASSWORD is not set")
        }
        
        return errors
    }
}

// MARK: - Environment Extensions

@available(iOS 17.0, *)
extension FlutterEnvironmentConfig {
    
    /// Check if running in development mode
    public var isDevelopment: Bool {
        return environment == "development"
    }
    
    /// Check if running in staging mode
    public var isStaging: Bool {
        return environment == "staging"
    }
    
    /// Check if running in production mode
    public var isProduction: Bool {
        return environment == "production"
    }
    
    /// Get environment-specific display name
    public var environmentDisplayName: String {
        switch environment {
        case "development":
            return "Development"
        case "staging":
            return "Staging"
        case "production":
            return "Production"
        default:
            return "Unknown"
        }
    }
}

// MARK: - Mock Configuration for Testing

@available(iOS 17.0, *)
extension FlutterEnvironmentConfig {
    
    /// Create a mock configuration for testing
    public static func mock(
        environment: String = "production",
        apiBaseUrl: String? = nil,
        storageBucket: String = "aroosi-ios.firebasestorage.app",
        firebaseProjectId: String = "aroosi-ios",
        firebaseGoogleAppId: String = "1:320943801797:ios:9698384f0913adeaf6b7ac",
        firebaseClientId: String = "762041256503-uc9qopr13761ictkgj53ba4gomtkvbha.apps.googleusercontent.com",
        firebaseApiKey: String = "AIzaSyDBO0qloVCqP7su4WnBL72yUkH7KooGyzY",
        firebaseGcmSenderId: String = "320943801797"
    ) -> FlutterEnvironmentConfig {
        let mock = FlutterEnvironmentConfig()
        
        // Set mock environment variables
        setenv("ENVIRONMENT", environment, 1)
        if let url = apiBaseUrl {
            setenv("API_BASE_URL", url, 1)
        }
        setenv("FIREBASE_STORAGE_BUCKET", storageBucket, 1)
        setenv("FIREBASE_IOS_PROJECT_ID", firebaseProjectId, 1)
        setenv("FIREBASE_IOS_GOOGLE_APP_ID", firebaseGoogleAppId, 1)
        setenv("FIREBASE_IOS_CLIENT_ID", firebaseClientId, 1)
        setenv("FIREBASE_IOS_API_KEY", firebaseApiKey, 1)
        setenv("FIREBASE_IOS_GCM_SENDER_ID", firebaseGcmSenderId, 1)
        
        return mock
    }
    
    /// Reset mock environment variables
    public func resetMock() {
        unsetenv("ENVIRONMENT")
        unsetenv("API_BASE_URL")
        unsetenv("FIREBASE_STORAGE_BUCKET")
        unsetenv("FIREBASE_IOS_PROJECT_ID")
        unsetenv("FIREBASE_IOS_GOOGLE_APP_ID")
        unsetenv("FIREBASE_IOS_CLIENT_ID")
        unsetenv("FIREBASE_IOS_API_KEY")
        unsetenv("FIREBASE_IOS_GCM_SENDER_ID")
        unsetenv("GOOGLESERVICE_INFO_PLIST_BASE64")
        unsetenv("IOS_PROFILE_BASE64")
        unsetenv("IOS_CERT_BASE64")
        unsetenv("IOS_CERT_PASSWORD")
    }
}
