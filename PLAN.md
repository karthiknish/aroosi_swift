# Aroosi Native iOS Migration Plan

This document outlines a phased approach for re-implementing the existing Flutter application (`aroosi_flutter`) as a fully native iOS app written in Swift/SwiftUI.

## Guiding Principles
- **Feature Parity First**: Match the current user experience before expanding scope.
- **Incremental Delivery**: Ship vertical slices per user flow to enable iterative validation.
- **Modular Architecture**: Separate concerns (UI, domain, data, services) to improve testability and maintainability.
- **Shared Assets & Config**: Reuse JSON datasets, images, Firebase config, analytics, and CI/CD automation wherever possible.
- **SwiftUI + Combine/Concurrency**: Prefer modern UIKit interop only when necessary.
- **Backend-First Implementation**: Wire every screen to live repositories before UI polish; placeholders allowed only in transient scaffolding stories.

## Phase 0 – Discovery & Foundations (1-2 weeks)
1. **Codebase Audit**
   - Catalog Flutter features by reading `/lib`, `/assets`, `/firebase`, `/scripts`, `/test`.
   - Identify critical flows (onboarding, authentication, profile, matchmaking, messaging, payments, settings, offline stories, analytics).
   - Document 3rd-party dependencies (Firebase Auth/Firestore/Storage, Razorpay/Stripe, Segment, etc.).
   - [x] Initial survey captured in `docs/ios-migration/phase0/feature-audit.md` and `docs/ios-migration/phase0/dependency-inventory.md`.
2. **Design Assets**
   - Export Figma/Flutter styles, color tokens, typography, and reusable components.
   - Inventory static assets in `/assets` and image generation scripts in `/seed_images`.
   - [x] Initial brand + asset inventory captured in `docs/ios-migration/phase0/design-assets.md` (follow-up: request Figma exports, font licensing).
3. **Data Contracts**
   - Extract JSON models and Firestore schema (from `firebase/` rules, `icebreaker_data.json`, `upload-icebreaker-questions.js`).
   - Define typed Swift models aligning with existing data sources.
   - [x] Firestore + REST notes tracked in `docs/ios-migration/phase0/data-contracts.md`.
   - [ ] Model deep dives underway: see `docs/ios-migration/phase0/data-models/` (`profiles.md`, `auth.md`, `chat.md`, `compatibility.md`, `engagement.md`, `safety-support.md`; billing deep dive currently on hold).
4. **Tooling Setup**
   - Decide CI stack (GitHub Actions vs existing fastlane lanes in `/fastlane`).
   - Choose dependency management (Swift Package Manager + CocoaPods only for legacy SDKs).
   - Baseline linting (SwiftLint), formatting (SwiftFormat), and static analysis (Xcode build settings, Sonar optional).
   - [x] Current automation and gaps captured in `docs/ios-migration/phase0/tooling.md` (Fastlane lanes missing, GitHub Actions uses Flutter-specific steps).

## Phase 1 – Project Bootstrap (1 week)
1. **Create Xcode Project**
   - Use Xcode 15+ to create an `AroosiSwift` SwiftUI lifecycle app targeting iOS 17 min.
   - Enable modules: Push Notifications, Background Modes, Keychain, Sign In with Apple if needed.
   - Configure bundle identifiers, provisioning, signing teams (reuse `build_ios.sh` patterns).
   - [ ] Project bootstrap playbook drafted in `native_ios/ProjectSetup.md` (requires execution once Apple credentials ready).
2. **Structure Workspace**
   - Adopt folder modules: `App`, `Features`, `Shared`, `Services`, `Resources`, `Tests`.
   - Link shared assets via asset catalogs; convert `.json` to Swift resources (SwiftPM `.process`).
   - Integrate SPM dependencies (Firebase via `Firebase`, `FirebaseFirestore`, `FirebaseAuth`, `FirebaseStorage`, `FirebaseCrashlytics`, `GoogleSignIn`, `SDWebImageSwiftUI`, `RevenueCat` or equivalent).
   - [x] Swift package + folder layout established under `native_ios/` (AppHost + `AroosiKit`).
   - [ ] Pending: add asset catalogs and resource processing once design exports arrive.
3. **Automation**
   - Port fastlane lanes to `aroosi_swift/fastlane` for build, test, deploy to TestFlight.
   - Create an `xcconfig`-driven configuration system for environments (dev, staging, prod).
   - Implement CI job to run `xcodebuild test` + SwiftLint + SwiftFormat.
   - [x] Base xcconfig set in `native_ios/Config/`.
   - [x] Fastlane skeleton available in `native_ios/fastlane/Fastfile` + lint/format configs.
   - [ ] GitHub Actions workflow `native-ios.yml` runs SwiftFormat/SwiftLint/`swift test`; expand to Xcode workspace once app target exists.

## Phase 2 – Core Infrastructure (2-3 weeks)
1. **Shared Layer**
   - [ ] Define `AppConfig`, `Environment`, `Secrets` loader reading from `.env` (reuse existing file).
   - [ ] Implement `Logger`, `AnalyticsClient`, `RemoteConfig`, `A/B testing`, `FeatureFlags`.
2. **Networking & Data**
   - [ ] Use `Firebase` SDK for realtime data; wrap Firestore collections in repository protocols.
   - [ ] Build `HTTPClient` for REST endpoints (if backend supplies non-Firebase APIs).
   - [ ] Implement caching (CoreData/SQLite) for offline data parity.
3. **Authentication**
   - [x] Implement Sign in with Apple as the primary authentication strategy.
   - [x] Manage secure token storage (Keychain) and account linking with existing Firebase users.
4. **Routing**
   - [ ] Establish navigation coordinator using SwiftUI `NavigationStack` + custom router for deep links and feature flags.

## Phase 3 – Feature Ports (6-10 weeks, rolling)
For each feature (match onboarding, discovery, chat, premium upgrades, settings, admin tools):
1. **UX Spec**: Map Flutter screens to SwiftUI views; update for iOS HIG where beneficial.
2. **Data Mapping**: Ensure Swift models align with Firestore documents; migrate business logic.
3. **State Management**: Use `ObservableObject` + `@State` + `@StateObject`, or adopt `Composable Architecture` if complexity demands.
4. **Testing**: Unit tests for view models, snapshot/UI tests using XCTest + ViewInspector/XCUI.
5. **Accessibility**: Verify VoiceOver, Dynamic Type, right-to-left support.
   - [x] Onboarding/auth vertical wires Sign in with Apple through `FirebaseAuthService` and preloads profile summaries via `FirestoreProfileRepository` (`native_ios/Sources/Features/Authentication/`).
   - [x] Service layer + `SystemSignInPresenter` expose `presentSignIn(from:)` for UIKit/coordinator flows sharing the same backend hooks.
   - [x] Chat vertical delivers messaging, unread synchronization, and updated chat UI tied into Firestore repositories (pending richer profile media once assets land).
   - [x] Profile vertical surfaces live ProfileView + MatchesView avatars sourced from Firestore, replacing placeholder headers with backend data.
   - [x] Settings vertical surfaces notification/email preferences and support contacts via `UserSettingsRepository`.
   - [ ] Replace any remaining placeholder content with live Firestore/REST-backed data before exiting each feature slice.

## Phase 4 – Polish & Pre-Launch (2-3 weeks)
- [ ] QA regression vs Flutter build; maintain user journeys in TestRail.
- [ ] Performance profiling with Instruments (launch time, memory usage, jank).
- [ ] Crash reporting, analytics event parity; integrate remote logging.
- [ ] Localization: port `.arb` to `.strings` using a converter script.
- [ ] App Store prep: metadata, screenshots, review guidelines (reuse `APPLE_APP_STORE_REVIEW.md`).

## Phase 5 – Launch & Post-Launch
- [ ] Gradual rollout via phased release/TestFlight groups.
- [ ] Collect user feedback, crash analytics, fix blockers.

## Deliverables Checklist
- [ ] 📁 `AroosiSwift.xcodeproj` with modular SwiftUI architecture.
- [ ] 🔐 Firebase + Authentication integration.
- [ ] 💬 Core feature parity (onboarding, matchmaking, chat, settings).
- [ ] 🧪 Automated tests (unit, snapshot, UI) hitting >70% coverage on view models.
- [ ] ⚙️ Fastlane + CI pipeline.
- [ ] 🌍 Localization + accessibility parity.
- [ ] 📦 App Store submission package and release notes.

## Pending Tasks
- [ ] Validate chat/matches data models in `docs/ios-migration/phase0/data-models/` once backend contracts stabilize.
- [ ] Execute the Xcode project setup play outlined in `native_ios/ProjectSetup.md` once Apple credentials are available.
- [ ] Import design exports to build asset catalogs and resource pipelines.
- [ ] Expand `native-ios.yml` GitHub Action to cover the future Xcode workspace.
- [ ] Expand multi-surface Sign in to legacy UIKit flows (e.g., push-deeplink reauth) once those surfaces exist.
- [ ] Integrate richer profile media in chat header once assets and delivery requirements are ready.
- [ ] Implement shared layer foundations (`AppConfig`, `Environment`, logging, analytics, feature flags).
- [ ] Stand up networking/data stack (Firestore repositories, REST client, offline cache strategy) beyond auth/onboarding/settings surface coverage.
- [ ] Define navigation coordinator architecture for deep links and feature routing.
- [ ] Audit all existing screens for placeholder UI/data and replace with production repositories before expanding scope (matches/profile/onboarding/settings now live).
- [x] Complete backend-first authentication flow (Sign in with Apple via SwiftUI + UIKit presenters).
- [x] Replace onboarding hero art (`onboarding-hero`) and tagline copy with Firestore-driven content.
- [x] Stand up settings feature screens (preferences, notifications, support) with live backend wiring.
- [ ] Add sign-out + premium management actions to Settings once backend contracts are finalized.

## Risks & Mitigations
- **Scope Creep**: Lock requirements per phase; use change control for net-new features.
- **Data Divergence**: Implement integration tests comparing Swift repos against production Firestore.
- **Team Familiarity**: Provide SwiftUI onboarding sessions for Flutter engineers; pair program initial features.
- **Parallel Maintenance**: Keep Flutter app in maintenance mode until native app achieves parity; share Firebase rules.

## Next Steps
- [ ] Approve plan and adjust timelines/resources.
- [ ] Spin up Xcode project skeleton (`native_ios/` folder) and wire Firebase config.
- [ ] Prioritize first feature slice (likely onboarding + authentication).
