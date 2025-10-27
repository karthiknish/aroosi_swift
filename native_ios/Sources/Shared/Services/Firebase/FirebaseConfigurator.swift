import Foundation
import FirebaseCore

@available(iOS 17.0.0, *)
public enum FirebaseConfigurator {
    private static let config = FlutterEnvironmentConfig()
    
    public static func configureIfNeeded() {
        guard FirebaseApp.app() == nil else { return }

        if let options = resolveOptions() {
            FirebaseApp.configure(options: options)
        } else {
            Logger.shared.error("Unable to locate Firebase configuration. Firebase will remain unconfigured until valid credentials are provided.")
        }
    }

    private static func resolveOptions() -> FirebaseOptions? {
        // First try environment variables (from Flutter app configuration)
        if let envOptions = createOptionsFromEnvironment() {
            return envOptions
        }
        
        let environment = ProcessInfo.processInfo.environment
        var candidates: [String] = []

        if let explicitName = environment["FIREBASE_PLIST"], !explicitName.isEmpty {
            candidates.append(explicitName)
        }

        candidates.append(contentsOf: [
            "GoogleService-Info-Debug",
            "GoogleService-Info-Staging",
            "GoogleService-Info-Prod",
            "GoogleService-Info"
        ])

        for name in candidates {
            if let options = loadOptions(named: name) {
                return options
            }
        }

        if let explicitPath = environment["GOOGLE_SERVICE_INFO_PATH"],
           let options = FirebaseOptions(contentsOfFile: explicitPath) {
            return sanitize(options)
        }

        return nil
    }

    private static func loadOptions(named plistName: String) -> FirebaseOptions? {
        if let url = Bundle.main.url(forResource: plistName, withExtension: "plist"),
           let options = FirebaseOptions(contentsOfFile: url.path) {
            return sanitize(options)
        }

        #if SWIFT_PACKAGE
        if let url = Bundle.module.url(forResource: plistName, withExtension: "plist"),
           let options = FirebaseOptions(contentsOfFile: url.path) {
            return sanitize(options)
        }
        #endif

        return nil
    }

    private static func sanitize(_ options: FirebaseOptions) -> FirebaseOptions? {
        let placeholders: [String?] = [options.apiKey, options.projectID, options.gcmSenderID, options.googleAppID]
        if placeholders.contains(where: isPlaceholder) {
            Logger.shared.error("Firebase configuration contains placeholder credentials. Provide real values via secure configuration before launching.")
            return nil
        }
        return options
    }

    private static func createOptionsFromEnvironment() -> FirebaseOptions? {
        // Use FlutterEnvironmentConfig to get Firebase configuration
        let apiKey = config.firebaseApiKey
        let googleAppID = config.firebaseGoogleAppId
        let projectID = config.firebaseProjectId
        let gcmSenderID = config.firebaseGcmSenderId
        let clientID = config.firebaseClientId
        let bundleID = config.firebaseBundleId
        let storageBucket = config.storageBucket
        
        // Validate that all required fields are available
        guard !apiKey.isEmpty,
              !googleAppID.isEmpty,
              !projectID.isEmpty,
              !gcmSenderID.isEmpty,
              !clientID.isEmpty,
              !bundleID.isEmpty else {
            Logger.shared.debug("Firebase environment variables not complete, falling back to plist files")
            return nil
        }
        
        // Check for placeholder values
        guard !isPlaceholder(apiKey),
              !isPlaceholder(googleAppID),
              !isPlaceholder(projectID),
              !isPlaceholder(gcmSenderID),
              !isPlaceholder(clientID) else {
            Logger.shared.error("Firebase configuration contains placeholder values. Please update App.env with real Firebase credentials.")
            return nil
        }
        
        let options = FirebaseOptions(googleAppID: googleAppID, gcmSenderID: gcmSenderID)
        options.apiKey = apiKey
        options.projectID = projectID
        options.clientID = clientID
        options.bundleID = bundleID
        
        if !storageBucket.isEmpty {
            options.storageBucket = storageBucket
        }
        
        Logger.shared.info("Firebase configured successfully using environment variables from FlutterEnvironmentConfig")
        return options
    }

    private static func isPlaceholder(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        let uppercased = trimmed.uppercased()
        return uppercased.contains("REPLACE_WITH") || uppercased.contains("YOUR_") || uppercased.contains("PLACEHOLDER")
    }
}
