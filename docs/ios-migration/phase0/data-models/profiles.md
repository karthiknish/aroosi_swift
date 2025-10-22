# Phase 0 · Data Model Notes · Profiles

## Overview
The Flutter `lib/features/profiles/models.dart` file defines the bulk of profile-related domain objects used across matchmaking, shortlist, family approval, and supervised conversations. These models rely heavily on Equatable, dynamic JSON parsing, and pragmatic integer timestamp handling. Swift equivalents will use `Codable`, `Hashable`, and strongly typed enumerations.

## Key Models & Migration Targets

### CulturalProfile
- Fields: religion, practice, mother tongue, languages array, values around marriage/culture importance (1-10 scale), optional family background/ethnicity.
- JSON fields are optional strings; ints default to 5 when missing.
- **Swift Plan**:
  ```swift
  struct CulturalProfile: Codable, Hashable {
      var religion: String?
      var religiousPractice: String?
      var motherTongue: String?
      var languages: [String]
      var familyValues: String?
      var marriageViews: String?
      var traditionalValues: String?
      var familyApprovalImportance: String?
      var religionImportance: Int
      var cultureImportance: Int
      var familyBackground: String?
      var ethnicity: String?
  }
  ```
  - Provide computed properties or enums for fields (e.g., `ReligiousPractice`) once backend constants confirmed.
  - Validation: ensure importance values remain within 1...10 (use `min/max` in Swift initializer).

### FamilyApprovalRequest
- Represents formal approval request to family members.
- Fields: id, requester/target IDs, status string (pending/approved/rejected/cancelled), created/ responded timestamps (epoch millis), optional message and response metadata, boolean `approved`.
- **Swift Plan**:
  ```swift
  struct FamilyApprovalRequest: Codable, Identifiable, Hashable {
      enum Status: String, Codable { case pending, approved, rejected, cancelled }
      var id: String
      var requesterId: String
      var targetUserId: String
      var status: Status
      var createdAt: Date
      var message: String
      var familyMemberId: String?
      var familyMemberName: String?
      var familyMemberRelation: String?
      var response: String?
      var respondedAt: Date?
      var approved: Bool
  }
  ```
  - Convert epoch millis to `Date` via `Date(timeIntervalSince1970: millis / 1000)`. Provide custom `CodingKeys` to handle ints.

### SupervisedConversation
- Handles chaperoned conversations with optional rule sets and time limits.
- Fields: participants, supervisor, status string (`active`, `paused`, etc.), createdAt, optional conversationId, rules, timeLimit, topicRestrictions, lastActivity.
- **Swift Plan**: similar to above with `enum Status: String`.
- `rules`, `topicRestrictions` arrays stored as `List<String>`; ensure `nil` vs empty array semantics handled.

### ShortlistEntry
- Minimal struct: userId, createdAt (epoch), optional fullName, profileImageUrls, note.
- Flutter uses `int.tryParse` fallback to now.
- **Swift Plan**:
  ```swift
  struct ShortlistEntry: Codable, Identifiable, Hashable {
      var id: String { userId }
      var userId: String
      var createdAt: Date
      var fullName: String?
      var profileImageURLs: [URL]
      var note: String?
  }
  ```
  - Parse image URLs via `URL(string:)`, drop invalid entries or log via Logger.

### ProfileSummary
- Lightweight card model: id, displayName, optional age/city/avatar, flags (favorite/shortlisted), `Date? lastActive`.
- Age is optional int; ensure mapping to `Int?` in Swift with safe decoding.

### FullProfile / ProfileDetails
- Later in file (not fully reviewed yet) there are comprehensive models for education, lifestyle, preferences, and verification statuses.
- Strategy: break into smaller Swift structs, group into nested modules (`Profile.Basic`, `Profile.Lifestyle`, etc.) for maintainability.

## Serialization Considerations
- Flutter models often call `.toString()` on fields to defensively coerce values. Swift should expect backend consistency but guard against `null` or unexpected types using custom decoders that log and default gracefully.
- Timestamps: standardize on `Int` milliseconds. Create extension `Date(iso8601Milliseconds:)` and `date.millisecondsSince1970` utilities.
- Booleans: some flags use `== true`. Swift decoders should map absent values to `false`.

## Storage & Sync
- Profiles fetched via REST (probably `profiles_repository.dart` hitting backend). Swift should create repository using `URLSession` with `JSONDecoder` configured for camelCase keys unless API uses snake_case (confirm via API responses).
- Shortlist entries also cached locally? Investigate `profiles_repository.dart` for persistence expectations.

## Follow-ups
1. Review remaining ~900 lines to catalog models for lifestyle, education, verification, compatibility scores.
2. Identify enumerations used across profiles (e.g., `religion`, `marriageViews`) and define canonical value sets.
3. Determine if Firestore uses these models or if backend REST returns same structure; adjust `Codable` strategy accordingly.
