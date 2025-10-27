````markdown
# Native iOS Project Skeleton

This directory hosts the Swift/SwiftUI implementation of the Aroosi application.

## Structure

```
native_ios/
├── Package.swift             # Swift Package manifest for the SwiftUI feature package
├── AppHost/                  # Placeholder iOS app target scaffolding (outside the package)
├── Config/                   # Environment-specific xcconfig files and secrets template
├── Sources/
│   ├── Features/
│   │   ├── Authentication/   # Sign in with Apple sheet & view model
│   │   │   ├── AuthView.swift
│   │   │   └── AuthViewModel.swift
│   │   ├── Onboarding/
│   │   │   └── OnboardingView.swift
│   │   └── Root/
│   │       ├── RootView.swift
│   │       └── RootViewModel.swift
│   └── Shared/
│       ├── Models/
│       │   └── UserProfile.swift
│       ├── Services/
│       │   ├── AppleSignInCoordinator.swift
│       │   ├── AuthProviding.swift
│       │   └── FirebaseAuthService.swift
│       └── Utilities/
│           ├── AppleSignInNonce.swift
│           └── Logger.swift
├── Tests/
│   ├── AuthViewModelTests.swift
│   └── RootViewModelTests.swift
└── fastlane/                 # Fastlane scaffold (lanes to be filled as the app matures)

## Tooling
- Linting via `.swiftlint.yml`
- Formatting via `.swiftformat`
- GitHub Actions workflow `.github/workflows/native-ios.yml` runs format, lint, and `swift test`
- Fastlane placeholder under `fastlane/` for future TestFlight/App Store automation
```

## Usage
1. `brew install swiftlint swiftformat`
2. `swift package resolve`
3. `xed .` and attach `native_ios/Package.swift` to a new (or existing) Xcode workspace.
4. Add an iOS 17+ app target (e.g. `AroosiSwiftApp`) and link the `AroosiKit` Swift package product.
5. Enable the **Sign in with Apple** capability on the host target and ensure the bundle identifier is registered with Apple.

> ⚠️ The generated project is intentionally lightweight. The first milestone is to convert it into an Xcode workspace that owns the app target and integrates this package for feature modules.

## Sign in with Apple + Firebase Checklist
1. In the Apple Developer portal, create a Sign in with Apple Service ID that matches the bundle identifier you use in Xcode.
2. In Firebase Console (`Authentication › Sign-in method`), enable **Apple** and paste the Service ID plus key configuration.
3. Download the updated `GoogleService-Info.plist` and add it to `AppHost/` (and eventually the real Xcode target).
4. Within Xcode, add the **Sign in with Apple** capability to the host target and ensure `SignInWithApple` appears in the entitlement file.
5. Run the app on an iOS 17+ simulator or device, tap **Sign in with Apple**, and verify that the Firebase user record is created/linked.
6. Confirm `swift test` passes so the package-level auth logic remains covered.
````