#if os(iOS)
import SwiftUI

/**
 * Reusable Search Filter Components
 *
 * A collection of consistent search filter components used across the app
 * for filtering profiles, search results, and other data.
 *
 * Features:
 * - Age range slider
 * - Location picker
 * - Interest tags selector
 * - Multi-select filters
 * - Single-select filters
 * - Clear filters functionality
 * - Consistent styling and animations
 */

// MARK: - Age Range Filter

@available(iOS 17, *)
public struct AgeRangeFilterView: View {
    // MARK: - Properties

    @Binding public var minAge: Int
    @Binding public var maxAge: Int
    public let range: ClosedRange<Int>
    public let style: AgeRangeStyle

    // MARK: - Initialization

    public init(
        minAge: Binding<Int>,
        maxAge: Binding<Int>,
        range: ClosedRange<Int> = 18...80,
        style: AgeRangeStyle = .default
    ) {
        self._minAge = minAge
        self._maxAge = maxAge
        self.range = range
        self.style = style
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Age Range")
                .font(style.titleFont)
                .foregroundStyle(style.titleColor)

            HStack {
                Text("\(minAge)")
                    .font(style.valueFont)
                    .foregroundStyle(style.valueColor)

                Spacer()

                Text("\(maxAge)")
                    .font(style.valueFont)
                    .foregroundStyle(style.valueColor)
            }

            // Custom range slider implementation
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    Rectangle()
                        .fill(style.trackColor)
                        .frame(height: style.trackHeight)
                        .cornerRadius(style.trackHeight / 2)

                    // Active track
                    Rectangle()
                        .fill(style.activeTrackColor)
                        .frame(height: style.trackHeight)
                        .cornerRadius(style.trackHeight / 2)
                        .offset(x: minThumbPosition, width: maxThumbPosition - minThumbPosition)

                    // Min thumb
                    Circle()
                        .fill(style.thumbColor)
                        .frame(width: style.thumbSize, height: style.thumbSize)
                        .offset(x: minThumbPosition - style.thumbSize / 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    handleMinDrag(value, geometry: geometry)
                                }
                        )

                    // Max thumb
                    Circle()
                        .fill(style.thumbColor)
                        .frame(width: style.thumbSize, height: style.thumbSize)
                        .offset(x: maxThumbPosition - style.thumbSize / 2)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    handleMaxDrag(value, geometry: geometry)
                                }
                        )
                }
            }
            .frame(height: style.thumbSize)
        }
        .padding(style.padding)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
    }

    // MARK: - Computed Properties

    private var minThumbPosition: CGFloat {
        let percentage = Double(minAge - range.lowerBound) / Double(range.upperBound - range.lowerBound)
        return CGFloat(percentage) * (UIScreen.main.bounds.width - style.padding.leading - style.padding.trailing - style.thumbSize)
    }

    private var maxThumbPosition: CGFloat {
        let percentage = Double(maxAge - range.lowerBound) / Double(range.upperBound - range.lowerBound)
        return CGFloat(percentage) * (UIScreen.main.bounds.width - style.padding.leading - style.padding.trailing - style.thumbSize)
    }

    // MARK: - Methods

    private func handleMinDrag(_ value: DragGesture.Value, geometry: GeometryProxy) {
        let totalWidth = geometry.size.width - style.thumbSize
        let newPosition = max(0, min(value.location.x - style.thumbSize / 2, totalWidth))
        let percentage = Double(newPosition / totalWidth)
        let newAge = Int(Double(range.lowerBound) + percentage * Double(range.upperBound - range.lowerBound))

        if newAge <= maxAge - 1 {
            minAge = newAge
        }
    }

    private func handleMaxDrag(_ value: DragGesture.Value, geometry: GeometryProxy) {
        let totalWidth = geometry.size.width - style.thumbSize
        let newPosition = max(0, min(value.location.x - style.thumbSize / 2, totalWidth))
        let percentage = Double(newPosition / totalWidth)
        let newAge = Int(Double(range.lowerBound) + percentage * Double(range.upperBound - range.lowerBound))

        if newAge >= minAge + 1 {
            maxAge = newAge
        }
    }
}

// MARK: - Location Filter

@available(iOS 17, *)
public struct LocationFilterView: View {
    // MARK: - Properties

    @Binding public var selectedLocation: String?
    public let locations: [String]
    public let style: LocationFilterStyle

    // MARK: - Initialization

    public init(
        selectedLocation: Binding<String?>,
        locations: [String],
        style: LocationFilterStyle = .default
    ) {
        self._selectedLocation = selectedLocation
        self.locations = locations
        self.style = style
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(style.titleFont)
                .foregroundStyle(style.titleColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: style.spacing) {
                    // "All" option
                    LocationChipView(
                        text: "All",
                        isSelected: selectedLocation == nil,
                        style: style.chipStyle
                    ) {
                        selectedLocation = nil
                    }

                    // Location options
                    ForEach(locations, id: \.self) { location in
                        LocationChipView(
                            text: location,
                            isSelected: selectedLocation == location,
                            style: style.chipStyle
                        ) {
                            selectedLocation = location
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(style.padding)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
    }
}

// MARK: - Interest Filter

@available(iOS 17, *)
public struct InterestFilterView: View {
    // MARK: - Properties

    @Binding public var selectedInterests: Set<String>
    public let availableInterests: [String]
    public let style: InterestFilterStyle
    public let maxSelections: Int?

    // MARK: - Initialization

    public init(
        selectedInterests: Binding<Set<String>>,
        availableInterests: [String],
        style: InterestFilterStyle = .default,
        maxSelections: Int? = nil
    ) {
        self._selectedInterests = selectedInterests
        self.availableInterests = availableInterests
        self.style = style
        self.maxSelections = maxSelections
    }

    // MARK: - Body

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Interests")
                    .font(style.titleFont)
                    .foregroundStyle(style.titleColor)

                Spacer()

                if let maxSelections = maxSelections {
                    Text("\(selectedInterests.count)/\(maxSelections)")
                        .font(style.countFont)
                        .foregroundStyle(style.countColor)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: style.columns), spacing: style.spacing) {
                ForEach(availableInterests, id: \.self) { interest in
                    InterestChipView(
                        text: interest,
                        isSelected: selectedInterests.contains(interest),
                        style: style.chipStyle,
                        isDisabled: maxSelections != nil && selectedInterests.count >= maxSelections && !selectedInterests.contains(interest)
                    ) {
                        if selectedInterests.contains(interest) {
                            selectedInterests.remove(interest)
                        } else {
                            if let maxSelections = maxSelections, selectedInterests.count >= maxSelections {
                                return
                            }
                            selectedInterests.insert(interest)
                        }
                    }
                }
            }
        }
        .padding(style.padding)
        .background(style.backgroundColor)
        .cornerRadius(style.cornerRadius)
    }
}

// MARK: - Filter Actions

@available(iOS 17, *)
public struct FilterActionsView: View {
    // MARK: - Properties

    public let onClear: () -> Void
    public let onApply: () -> Void
    public let style: FilterActionsStyle
    public let hasActiveFilters: Bool

    // MARK: - Initialization

    public init(
        onClear: @escaping () -> Void,
        onApply: @escaping () -> Void,
        style: FilterActionsStyle = .default,
        hasActiveFilters: Bool = false
    ) {
        self.onClear = onClear
        self.onApply = onApply
        self.style = style
        self.hasActiveFilters = hasActiveFilters
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 12) {
            // Clear button
            Button(action: onClear) {
                Text("Clear All")
                    .font(style.clearFont)
                    .foregroundStyle(style.clearTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(style.buttonPadding)
                    .background(style.clearBackgroundColor, in: RoundedRectangle(cornerRadius: style.cornerRadius))
            }
            .disabled(!hasActiveFilters)
            .opacity(hasActiveFilters ? 1.0 : 0.5)

            // Apply button
            Button(action: onApply) {
                Text("Apply Filters")
                    .font(style.applyFont)
                    .foregroundStyle(style.applyTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(style.buttonPadding)
                    .background(style.applyBackgroundColor, in: RoundedRectangle(cornerRadius: style.cornerRadius))
            }
        }
        .padding(style.padding)
        .background(style.backgroundColor)
    }
}

// MARK: - Chip Components

@available(iOS 17, *)
public struct LocationChipView: View {
    // MARK: - Properties

    public let text: String
    public let isSelected: Bool
    public let style: ChipStyle
    public let onTap: () -> Void

    // MARK: - Initialization

    public init(
        text: String,
        isSelected: Bool,
        style: ChipStyle,
        onTap: @escaping () -> Void
    ) {
        self.text = text
        self.isSelected = isSelected
        self.style = style
        self.onTap = onTap
    }

    // MARK: - Body

    public var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(isSelected ? style.selectedFont : style.font)
                .foregroundStyle(isSelected ? style.selectedTextColor : style.textColor)
                .padding(style.padding)
                .background(
                    isSelected ? style.selectedBackgroundColor : style.backgroundColor,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? style.selectedBorderColor : style.borderColor, lineWidth: style.borderWidth)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 17, *)
public struct InterestChipView: View {
    // MARK: - Properties

    public let text: String
    public let isSelected: Bool
    public let style: ChipStyle
    public let isDisabled: Bool
    public let onTap: () -> Void

    // MARK: - Initialization

    public init(
        text: String,
        isSelected: Bool,
        style: ChipStyle,
        isDisabled: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.text = text
        self.isSelected = isSelected
        self.style = style
        self.isDisabled = isDisabled
        self.onTap = onTap
    }

    // MARK: - Body

    public var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(isSelected ? style.selectedFont : style.font)
                .foregroundStyle(isDisabled ? style.disabledTextColor : (isSelected ? style.selectedTextColor : style.textColor))
                .padding(style.padding)
                .background(
                    isDisabled ? style.disabledBackgroundColor : (isSelected ? style.selectedBackgroundColor : style.backgroundColor),
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(isDisabled ? style.disabledBorderColor : (isSelected ? style.selectedBorderColor : style.borderColor), lineWidth: style.borderWidth)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
    }
}

// MARK: - Style Definitions

@available(iOS 17, *)
public struct AgeRangeStyle {
    public let titleFont: Font
    public let titleColor: Color
    public let valueFont: Font
    public let valueColor: Color
    public let trackColor: Color
    public let activeTrackColor: Color
    public let thumbColor: Color
    public let trackHeight: CGFloat
    public let thumbSize: CGFloat
    public let backgroundColor: Color
    public let padding: EdgeInsets
    public let cornerRadius: CGFloat

    public static let `default` = AgeRangeStyle(
        titleFont: AroosiTypography.body(weight: .semibold),
        titleColor: AroosiColors.text,
        valueFont: AroosiTypography.heading(size: 16, weight: .medium),
        valueColor: AroosiColors.primary,
        trackColor: AroosiColors.border,
        activeTrackColor: AroosiColors.primary,
        thumbColor: AroosiColors.primary,
        trackHeight: 4,
        thumbSize: 24,
        backgroundColor: AroosiColors.surface,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: 12
    )
}

@available(iOS 17, *)
public struct LocationFilterStyle {
    public let titleFont: Font
    public let titleColor: Color
    public let spacing: CGFloat
    public let chipStyle: ChipStyle
    public let backgroundColor: Color
    public let padding: EdgeInsets
    public let cornerRadius: CGFloat

    public static let `default` = LocationFilterStyle(
        titleFont: AroosiTypography.body(weight: .semibold),
        titleColor: AroosiColors.text,
        spacing: 8,
        chipStyle: .location,
        backgroundColor: AroosiColors.surface,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: 12
    )
}

@available(iOS 17, *)
public struct InterestFilterStyle {
    public let titleFont: Font
    public let titleColor: Color
    public let countFont: Font
    public let countColor: Color
    public let columns: Int
    public let spacing: CGFloat
    public let chipStyle: ChipStyle
    public let backgroundColor: Color
    public let padding: EdgeInsets
    public let cornerRadius: CGFloat

    public static let `default` = InterestFilterStyle(
        titleFont: AroosiTypography.body(weight: .semibold),
        titleColor: AroosiColors.text,
        countFont: AroosiTypography.caption(),
        countColor: AroosiColors.muted,
        columns: 2,
        spacing: 8,
        chipStyle: .interest,
        backgroundColor: AroosiColors.surface,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: 12
    )
}

@available(iOS 17, *)
public struct FilterActionsStyle {
    public let clearFont: Font
    public let clearTextColor: Color
    public let clearBackgroundColor: Color
    public let applyFont: Font
    public let applyTextColor: Color
    public let applyBackgroundColor: Color
    public let buttonPadding: EdgeInsets
    public let cornerRadius: CGFloat
    public let padding: EdgeInsets
    public let backgroundColor: Color

    public static let `default` = FilterActionsStyle(
        clearFont: AroosiTypography.body(weight: .medium),
        clearTextColor: AroosiColors.muted,
        clearBackgroundColor: AroosiColors.surface,
        applyFont: AroosiTypography.body(weight: .semibold),
        applyTextColor: .white,
        applyBackgroundColor: AroosiColors.primary,
        buttonPadding: EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20),
        cornerRadius: 12,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        backgroundColor: AroosiColors.background
    )
}

@available(iOS 17, *)
public struct ChipStyle {
    public let font: Font
    public let selectedFont: Font
    public let textColor: Color
    public let selectedTextColor: Color
    public let disabledTextColor: Color
    public let backgroundColor: Color
    public let selectedBackgroundColor: Color
    public let disabledBackgroundColor: Color
    public let borderColor: Color
    public let selectedBorderColor: Color
    public let disabledBorderColor: Color
    public let borderWidth: CGFloat
    public let padding: EdgeInsets

    public static let location = ChipStyle(
        font: AroosiTypography.body(size: 14),
        selectedFont: AroosiTypography.body(size: 14, weight: .semibold),
        textColor: AroosiColors.text,
        selectedTextColor: .white,
        disabledTextColor: AroosiColors.muted,
        backgroundColor: AroosiColors.surface,
        selectedBackgroundColor: AroosiColors.primary,
        disabledBackgroundColor: AroosiColors.muted.opacity(0.3),
        borderColor: AroosiColors.border,
        selectedBorderColor: AroosiColors.primary,
        disabledBorderColor: AroosiColors.muted,
        borderWidth: 1,
        padding: EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    )

    public static let interest = ChipStyle(
        font: AroosiTypography.caption(size: 13),
        selectedFont: AroosiTypography.caption(size: 13, weight: .semibold),
        textColor: AroosiColors.text,
        selectedTextColor: .white,
        disabledTextColor: AroosiColors.muted,
        backgroundColor: AroosiColors.surface,
        selectedBackgroundColor: AroosiColors.primary,
        disabledBackgroundColor: AroosiColors.muted.opacity(0.3),
        borderColor: AroosiColors.border,
        selectedBorderColor: AroosiColors.primary,
        disabledBorderColor: AroosiColors.muted,
        borderWidth: 1,
        padding: EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
    )
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            AgeRangeFilterView(
                minAge: .constant(25),
                maxAge: .constant(35)
            )

            LocationFilterView(
                selectedLocation: .constant("Kabul"),
                locations: ["Kabul", "Herat", "Mazar-i-Sharif", "Jalalabad"]
            )

            InterestFilterView(
                selectedInterests: .constant(["Reading", "Travel"]),
                availableInterests: ["Reading", "Travel", "Cooking", "Sports", "Music", "Art"],
                maxSelections: 4
            )

            FilterActionsView(
                onClear: { print("Clear filters") },
                onApply: { print("Apply filters") },
                hasActiveFilters: true
            )
        }
        .padding()
    }
    .background(AroosiColors.background)
}

#endif
