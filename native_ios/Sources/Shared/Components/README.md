# Aroosi Reusable Components

This directory contains reusable SwiftUI components designed for consistency across the Aroosi iOS app. All components follow the app's design system and provide a unified user experience.

## 📁 Component Structure

```
Components/
├── README.md                           # This documentation
├── ProfileCardView.swift               # Reusable profile card component
├── AsyncImageView.swift                # Async image loading component
├── FormInputs.swift                    # Form input components
├── SearchFilters.swift                 # Search filter components
├── ProfileDetailComponents.swift       # Profile detail components
└── AroosiToast.swift                   # Toast notification component
```

## 🎨 Design Principles

- **Consistency**: All components follow the Aroosi design system
- **Reusability**: Components are designed to be used across multiple screens
- **Customization**: Each component offers style variants and customization options
- **Accessibility**: All components include proper accessibility labels and support
- **Performance**: Optimized for smooth animations and efficient rendering

---

## 📱 ProfileCardView

A comprehensive profile card component used for displaying user profiles in search results, shortlists, and matches.

### Features
- Async image loading with fallbacks
- Profile information display (name, age, location, bio)
- Interest tags with horizontal scrolling
- Multiple style variants (default, compact, prominent)
- Tap gesture handling
- Responsive design

### Usage

```swift
ProfileCardView(
    profile: profile,
    onTap: {
        // Handle card tap
        coordinator.push(.profileDetail(profile.id))
    },
    style: .default,
    shadow: .medium
)
```

### Style Variants
- `.default`: Standard profile card with full information
- `.compact`: Smaller version for limited space
- `.prominent`: Larger version for featured profiles

---

## 🖼️ AsyncImageView

A robust async image loading component with proper loading states, error handling, and fallbacks.

### Features
- Async image loading with progress indicators
- Customizable placeholder images
- Error handling with fallback options
- Multiple shape options (circle, rounded rectangle, rectangle)
- Configurable sizing and aspect ratios
- Accessibility support

### Usage

```swift
// Basic usage
AsyncImageView(
    url: profile.avatarURL,
    shape: .circle,
    size: .medium
)

// Convenience initializers
AsyncImageView.avatar(url: profile.avatarURL, name: profile.displayName)
AsyncImageView.profile(url: profile.avatarURL)
AsyncImageView.banner(url: profile.bannerURL)
AsyncImageView.thumbnail(url: profile.thumbnailURL)
```

### Shape Options
- `.circle`: Circular images for avatars
- `.roundedRectangle(cornerRadius: CGFloat)`: Rounded corners
- `.rectangle`: Standard rectangular images

### Size Options
- `.small`: 40x40 points
- `.medium`: 80x80 points
- `.large`: 120x120 points
- `.custom(width: CGFloat, height: CGFloat)`: Custom dimensions
- `.square(CGFloat)`: Square with specified dimension

---

## 📝 FormInputs

A collection of form input components with validation support.

### Components

#### AroosiTextField
Standard text input with validation support.

```swift
AroosiTextField(
    text: $name,
    placeholder: "Enter your name",
    validation: RequiredValidationRule()
)
```

#### AroosiSecureField
Password input with show/hide toggle.

```swift
AroosiSecureField(
    text: $password,
    placeholder: "Enter your password",
    validation: MinLengthValidationRule(minLength: 8)
)
```

#### AroosiTextArea
Multi-line text input for longer content.

```swift
AroosiTextArea(
    text: $bio,
    placeholder: "Tell us about yourself...",
    style: .large
)
```

#### AroosiToggle
Toggle switch with title and description.

```swift
AroosiToggle(
    isOn: $notificationsEnabled,
    title: "Enable notifications",
    description: "Receive updates about new matches"
)
```

#### AroosiStepper
Numeric input with increment/decrement buttons.

```swift
AroosiStepper(
    value: $age,
    title: "Age",
    range: 18...80
)
```

### Validation Rules
- `RequiredValidationRule`: Ensures field is not empty
- `EmailValidationRule`: Validates email format
- `MinLengthValidationRule`: Ensures minimum character count

---

## 🔍 SearchFilters

Search filter components for profile filtering and search functionality.

### Components

#### AgeRangeFilterView
Dual-handle slider for age range selection.

```swift
AgeRangeFilterView(
    minAge: $minAge,
    maxAge: $maxAge,
    range: 18...80
)
```

#### LocationFilterView
Horizontal scrollable location chips.

```swift
LocationFilterView(
    selectedLocation: $selectedLocation,
    locations: ["Kabul", "Herat", "Mazar-i-Sharif"]
)
```

#### InterestFilterView
Multi-select interest tags with maximum selection limit.

```swift
InterestFilterView(
    selectedInterests: $selectedInterests,
    availableInterests: allInterests,
    maxSelections: 5
)
```

#### FilterActionsView
Clear and apply filter buttons.

```swift
FilterActionsView(
    onClear: { clearFilters() },
    onApply: { applyFilters() },
    hasActiveFilters: hasActiveFilters
)
```

---

## 👤 ProfileDetailComponents

Components for displaying comprehensive profile information.

### Components

#### ProfileHeaderView
Displays name, age, location, and last active status.

```swift
ProfileHeaderView(
    profile: profile,
    style: .default
)
```

#### BioSectionView
Expandable bio text with show more/less functionality.

```swift
BioSectionView(
    bio: profile.bio,
    style: .default
)
```

#### InterestsSectionView
Grid layout of interest tags.

```swift
InterestsSectionView(
    interests: profile.interests,
    style: .default
)
```

#### QuickFactsSectionView
Grid of quick fact items with icons.

```swift
QuickFactsSectionView(
    facts: [
        QuickFact(icon: "graduationcap", label: "Education", value: "Master's"),
        QuickFact(icon: "briefcase", label: "Profession", value: "Teacher")
    ]
)
```

#### PhotoGalleryView
Photo gallery with thumbnails and full-screen viewing.

```swift
PhotoGalleryView(
    photos: profile.photos,
    style: .default
)
```

#### ProfileActionsView
Action buttons for like, pass, and message.

```swift
ProfileActionsView(
    onLike: { likeProfile() },
    onPass: { passProfile() },
    onMessage: { messageProfile() }
)
```

---

## 🎯 Best Practices

### 1. Consistent Usage
- Use the same component variants across similar screens
- Follow the established style patterns
- Maintain consistent spacing and sizing

### 2. Performance
- Use lazy loading for large lists
- Optimize image sizes for different use cases
- Avoid unnecessary re-renders

### 3. Accessibility
- Always provide accessibility labels
- Support dynamic type sizing
- Ensure proper contrast ratios

### 4. Customization
- Use style variants instead of custom modifications
- Extend existing styles when needed
- Maintain design system consistency

---

## 🔄 Migration Guide

### From Custom Components
1. Identify custom components that match reusable ones
2. Replace with reusable components
3. Apply appropriate styles and configurations
4. Test functionality and appearance

### Example Migration

**Before:**
```swift
// Custom profile card
ZStack {
    AsyncImage(url: profile.avatarURL) { phase in
        // Custom implementation
    }
    // Custom overlay and info
}
```

**After:**
```swift
// Reusable component
ProfileCardView(
    profile: profile,
    onTap: { handleTap() },
    style: .default
)
```

---

## 🧪 Testing

### Component Testing
- Test all style variants
- Verify accessibility features
- Test with different data states
- Validate performance with large datasets

### Integration Testing
- Test components in different screen contexts
- Verify consistent behavior across the app
- Test user interactions and animations

---

## 📈 Future Enhancements

### Planned Components
- `ChatBubbleView`: Message bubble component
- `NotificationCardView`: Notification display component
- `OnboardingStepView`: Onboarding step component
- `SettingsItemView`: Settings row component

### Feature Enhancements
- More animation options
- Additional style variants
- Enhanced accessibility features
- Performance optimizations

---

## 📞 Support

For questions about component usage or to request new components:
1. Check this documentation first
2. Review existing component implementations
3. Contact the development team

---

**Last Updated**: October 27, 2025  
**Version**: 1.0.0  
**Maintained by**: Aroosi iOS Development Team
