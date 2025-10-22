# Phase 0 · Data Model Notes · Engagement & Retention

## Quick Picks (Daily Recommendations)
Source: `lib/features/engagement/quick_picks_repository.dart`
- Endpoint: `GET /engagement/quick-picks` → returns `{ success: true, data: { profiles: [...] } }`.
- Each profile entry includes `userId`, `profile` map with `fullName`, `profileImageUrls`, `dateOfBirth`, `city`, `createdAt`.
- Converted to `ProfileSummary` (from `profiles/models.dart`).
- **Swift Approach**:
  ```swift
  struct QuickPickResponse: Codable {
      var profiles: [QuickPick]
  }

  struct QuickPick: Codable, Identifiable {
      var id: String
      var displayName: String
      var avatarURL: URL?
      var city: String?
      var age: Int?
      var lastActive: Date?
  }
  ```
  - Provide helper to compute age from `dateOfBirth`.
  - Repository should expose async method `fetchQuickPicks(day: String?)` returning `[ProfileSummary]` equivalent.
  - POST `/engagement/quick-picks` with payload `{ toUserId, action }` for like/skip; map to Swift `enum QuickPickAction { case like, skip }`.

## Icebreaker Service
Source: `lib/features/engagement/icebreaker_service.dart`
- GET `/icebreakers` returns either `{ success: true, data: [...] }` or raw array. Each item has `id`/`questionId`, `text` (or `question`), `answered` bool, optional `answer` string.
- POST `/icebreakers/answer` with `{ questionId, answer }` -> returns success boolean.
- **Swift Model**:
  ```swift
  struct IcebreakerQuestion: Codable, Identifiable, Hashable {
      var id: String
      var text: String
      var answered: Bool
      var answer: String?
  }
  ```
  - Repository should normalize server variations; fallback to empty array on malformed data.
  - Use `URLSession` client; integrate with Combine or async/await.

## Notifications & Nudges
- Additional retention features may exist under `features/engagement` (e.g., push/in-app prompts). Need to review once modules implemented in Swift.
- Quick picks rely on `ProfileSummary` library; ensure shared model accessible in Swift target.

## Migration Considerations
1. Standardize server responses: consider requesting backend to always return consistent envelope to simplify decoding.
2. Add error logging via shared `Logger` to capture parsing issues (like missing `dateOfBirth`).
3. Ensure actions (like/skip) surface user feedback on failure; Flutter version throws generic `Exception`.
4. Icebreaker seeding uses Firebase JSON; native app should integrate with same dataset for offline previews/testing.
