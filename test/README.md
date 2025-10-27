# Aroosi iOS Test Suite

This directory contains comprehensive test coverage for the Aroosi iOS application.

## Test Structure

### Unit Tests
- **Authentication Tests** - Sign in with Apple, user session management
- **Dashboard Tests** - Real-time data loading, stats aggregation
- **Chat Tests** - Message sending, conversation management
- **Profile Tests** - Profile creation, editing, validation
- **Matching Tests** - Match discovery, interest sending
- **Settings Tests** - Preferences, notifications, account management

### Integration Tests
- **Firebase Integration** - Backend connectivity, data persistence
- **Navigation Tests** - Deep linking, route handling
- **Localization Tests** - Multi-language support

### UI Tests
- **User Journey Tests** - Critical user workflows
- **Accessibility Tests** - VoiceOver, Dynamic Type

## Running Tests

```bash
# Run all tests
swift test

# Run specific test target
swift test --filter AroosiKitTests

# Run with coverage
swift test --enable-code-coverage
```

## Test Coverage Target: 70%+

Current coverage is being built incrementally. Priority areas:
1. Authentication flows ✅
2. Core user features 🔄
3. Backend integration 🔄
4. Error handling ⏳

## Test Data

Uses mock services and test fixtures to ensure:
- Fast execution
- Reliable results
- No external dependencies
- Data privacy compliance
