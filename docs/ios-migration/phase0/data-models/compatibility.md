# Phase 0 · Data Model Notes · Compatibility & Questionnaires

## Source: `lib/features/compatibility/models.dart`

### IslamicCompatibilityCategory
- Defines grouped questionnaire categories (e.g., faith practice, family values).
- Fields: `id`, `name`, `description`, weight (`double` 0-1), list of `CompatibilityQuestion`.
- Swift equivalent can be simple struct:
  ```swift
  struct CompatibilityCategory: Codable, Hashable, Identifiable {
      var id: String
      var name: String
      var description: String
      var weight: Double
      var questions: [CompatibilityQuestion]
  }
  ```

### CompatibilityQuestion
- Fields: `id`, `text`, `type` (enum `QuestionType`), `options`, `isRequired` bool (default true).
- `QuestionType` options: singleChoice, multipleChoice, scale, yesNo.
- **Swift Plan**: create `enum QuestionType: String, Codable` and `struct CompatibilityQuestion` with `[QuestionOption]`.

### QuestionOption
- Fields: `id`, `text`, `value` (double 0-1 representing scoring weight).
- Swift struct `QuestionOption` with `Double value`.

### CompatibilityResponse
- Represents a user’s answers to questionnaire.
- Fields: `userId`, `responses` map (`questionId -> value(s)`), `completedAt` `DateTime`.
- Swift approach: `struct CompatibilityResponse: Codable` with `[String: CodableValue]` for responses. Consider typed wrapper for arrays vs scalars. Could adopt `[String: CompatibilityAnswer]` where `CompatibilityAnswer` is enum `.single(String)`, `.multiple([String])`, `.scaled(Double)`, `.boolean(Bool)`.

### CompatibilityScore
- Fields: two user IDs, `overallScore` (0-100), `categoryScores` map (categoryId -> double), `calculatedAt`, optional `detailedBreakdown` map.
- Provides helper methods to map to textual level/description.
- Swift struct with computed properties replicating human-readable text.

### CompatibilityReport & FamilyFeedback
- `CompatibilityReport`: ties two users, `CompatibilityScore`, generation date, optional `familyFeedback` array, `isShared` flag.
- `FamilyFeedback`: id, reportId, family member name, relationship, textual feedback, `createdAt`, enum `ApprovalStatus` (pending/approved/rejected).
- Swift should use nested types (e.g., `CompatibilityReport.FamilyFeedback`).

## Additional Data
- `questions_data.dart` likely contains seeded questions; convert to JSON bundle for Swift or fetch from backend.
- `compatibility_service.dart` calculates scores using responses; port logic to Swift service, ensuring identical scoring formulas.

## Considerations for Swift Migration
1. Standardize enumerations: `QuestionType`, `ApprovalStatus` as `RawRepresentable` strings for compatibility.
2. Responses map currently `Map<String, dynamic>`; confirm actual server response structure to design typed Swift models.
3. `weight` values may require precision (Double). Keep within 0...1; clamp values in Swift initializer.
4. Determine storage: responses likely persisted in Firestore or backend; Swift should integrate via repository pattern with Combine/async.
5. Provide localized descriptions for compatibility levels; call `getCompatibilityLevel()` logic from Swift computed property.
