#if os(iOS)
import SwiftUI

/**
 * Reusable Form Input Components
 * 
 * A collection of consistent form input components used across the app
 * for user input, validation, and data entry.
 * 
 * Features:
 * - Text fields with validation
 * - Secure text fields for passwords
 * - Text areas for multi-line input
 * - Pickers for selection
 * - Toggle switches
 * - Steppers for numeric input
 * - Consistent styling and animations
 * - Accessibility support
 */

// MARK: - Text Field Component

@available(iOS 17, *)
public struct AroosiTextField: View {
    
    // MARK: - Properties
    
    @Binding public var text: String
    public let placeholder: String
    public let style: AroosiTextFieldVisualStyle
    public let validation: ValidationRule?
    @State public var isValid: Bool = true
    @State public var errorMessage: String?
    
    // MARK: - Initialization
    
    public init(
        text: Binding<String>,
        placeholder: String,
        style: AroosiTextFieldVisualStyle = .default,
        validation: ValidationRule? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.style = style
        self.validation = validation
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(placeholder, text: $text)
                .textFieldStyle(AroosiTextFieldFieldStyle(style: style))
                .onChange(of: text) { _, newValue in
                    validateInput(newValue)
                }
            
            if let errorMessage = errorMessage, !isValid {
                Text(errorMessage)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.error)
            }
        }
    }
    
    // MARK: - Methods
    
    private func validateInput(_ input: String) {
        guard let validation = validation else {
            isValid = true
            errorMessage = nil
            return
        }
        
        let result = validation.validate(input)
        isValid = result.isValid
        errorMessage = result.isValid ? nil : result.message
    }
}

// MARK: - Secure Text Field Component

@available(iOS 17, *)
public struct AroosiSecureField: View {
    
    // MARK: - Properties
    
    @Binding public var text: String
    public let placeholder: String
    public let style: AroosiTextFieldVisualStyle
    public let validation: ValidationRule?
    @State public var isValid: Bool = true
    @State public var errorMessage: String?
    @State public var isSecure: Bool = true
    
    // MARK: - Initialization
    
    public init(
        text: Binding<String>,
        placeholder: String,
        style: AroosiTextFieldVisualStyle = .default,
        validation: ValidationRule? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.style = style
        self.validation = validation
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .textFieldStyle(AroosiTextFieldFieldStyle(style: style))
                .onChange(of: text) { _, newValue in
                    validateInput(newValue)
                }
                
                Button(action: {
                    isSecure.toggle()
                }) {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                        .foregroundStyle(AroosiColors.muted)
                }
            }
            
            if let errorMessage = errorMessage, !isValid {
                Text(errorMessage)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.error)
            }
        }
    }
    
    // MARK: - Methods
    
    private func validateInput(_ input: String) {
        guard let validation = validation else {
            isValid = true
            errorMessage = nil
            return
        }
        
        let result = validation.validate(input)
        isValid = result.isValid
        errorMessage = result.isValid ? nil : result.message
    }
}

// MARK: - Text Area Component

@available(iOS 17, *)
public struct AroosiTextArea: View {
    
    // MARK: - Properties
    
    @Binding public var text: String
    public let placeholder: String
    public let style: AroosiTextAreaStyle
    public let validation: ValidationRule?
    @State public var isValid: Bool = true
    @State public var errorMessage: String?
    
    // MARK: - Initialization
    
    public init(
        text: Binding<String>,
        placeholder: String,
        style: AroosiTextAreaStyle = .default,
        validation: ValidationRule? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.style = style
        self.validation = validation
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(style.placeholderFont)
                        .foregroundStyle(style.placeholderColor)
                        .padding(style.padding)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $text)
                    .font(style.font)
                    .foregroundStyle(style.textColor)
                    .padding(style.padding)
                    .background(style.backgroundColor)
                    .cornerRadius(style.cornerRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: style.cornerRadius)
                            .stroke(style.borderColor, lineWidth: style.borderWidth)
                    )
                    .onChange(of: text) { _, newValue in
                        validateInput(newValue)
                    }
            }
            .frame(height: style.height)
            
            if let errorMessage = errorMessage, !isValid {
                Text(errorMessage)
                    .font(AroosiTypography.caption())
                    .foregroundStyle(AroosiColors.error)
            }
        }
    }
    
    // MARK: - Methods
    
    private func validateInput(_ input: String) {
        guard let validation = validation else {
            isValid = true
            errorMessage = nil
            return
        }
        
        let result = validation.validate(input)
        isValid = result.isValid
        errorMessage = result.isValid ? nil : result.message
    }
}

// MARK: - Picker Component

@available(iOS 17, *)
public struct AroosiPicker<T: Hashable & CaseIterable>: View where T.AllCases.Element == T {
    
    // MARK: - Properties
    
    @Binding public var selection: T
    public let title: String
    public let style: AroosiPickerVisualStyle
    public let options: [T]
    
    // MARK: - Initialization
    
    public init(
        selection: Binding<T>,
        title: String,
        style: AroosiPickerVisualStyle = .default,
        options: [T] = Array(T.allCases)
    ) {
        self._selection = selection
        self.title = title
        self.style = style
        self.options = options
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(style.titleFont)
                .foregroundStyle(style.titleColor)
            
            Picker(title, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(displayText(for: option))
                        .tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundStyle(style.textColor)
        }
    }
    
    // MARK: - Methods
    
    private func displayText(for option: T) -> String {
        if let stringOption = option as? CustomStringConvertible {
            return stringOption.description
        }
        return String(describing: option)
    }
}

// MARK: - Toggle Component

@available(iOS 17, *)
public struct AroosiToggle: View {
    
    // MARK: - Properties
    
    @Binding public var isOn: Bool
    public let title: String
    public let description: String?
    public let style: AroosiToggleVisualStyle
    
    // MARK: - Initialization
    
    public init(
        isOn: Binding<Bool>,
        title: String,
        description: String? = nil,
        style: AroosiToggleVisualStyle = .default
    ) {
        self._isOn = isOn
        self.title = title
        self.description = description
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(style.titleFont)
                        .foregroundStyle(style.titleColor)
                    
                    if let description = description {
                        Text(description)
                            .font(style.descriptionFont)
                            .foregroundStyle(style.descriptionColor)
                    }
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .tint(style.tintColor)
            }
            .padding(style.padding)
            .background(style.backgroundColor)
            .cornerRadius(style.cornerRadius)
        }
    }
}

// MARK: - Stepper Component

@available(iOS 17, *)
public struct AroosiStepper: View {
    
    // MARK: - Properties
    
    @Binding public var value: Int
    public let title: String
    public let range: ClosedRange<Int>
    public let style: AroosiStepperVisualStyle
    
    // MARK: - Initialization
    
    public init(
        value: Binding<Int>,
        title: String,
        range: ClosedRange<Int> = 0...100,
        style: AroosiStepperVisualStyle = .default
    ) {
        self._value = value
        self.title = title
        self.range = range
        self.style = style
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(style.titleFont)
                .foregroundStyle(style.titleColor)
            
            HStack {
                Button(action: {
                    if value > range.lowerBound {
                        value -= 1
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(style.buttonTextColor)
                        .frame(width: 32, height: 32)
                        .background(style.buttonBackgroundColor, in: Circle())
                }
                .disabled(value <= range.lowerBound)
                
                Text("\(value)")
                    .font(style.valueFont)
                    .foregroundStyle(style.valueColor)
                    .frame(minWidth: 40)
                
                Button(action: {
                    if value < range.upperBound {
                        value += 1
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(style.buttonTextColor)
                        .frame(width: 32, height: 32)
                        .background(style.buttonBackgroundColor, in: Circle())
                }
                .disabled(value >= range.upperBound)
                
                Spacer()
            }
        }
    }
}

// MARK: - Style Definitions

@available(iOS 17, *)
public struct AroosiTextFieldVisualStyle {
    public let font: Font
    public let textColor: Color
    public let backgroundColor: Color
    public let borderColor: Color
    public let borderWidth: CGFloat
    public let cornerRadius: CGFloat
    public let padding: EdgeInsets
    
    public static let `default` = AroosiTextFieldVisualStyle(
        font: AroosiTypography.body(),
        textColor: AroosiColors.text,
        backgroundColor: AroosiColors.surface,
        borderColor: AroosiColors.border,
        borderWidth: 1,
        cornerRadius: 12,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    )
    
    public static let prominent = AroosiTextFieldVisualStyle(
        font: AroosiTypography.body(size: 18),
        textColor: AroosiColors.text,
        backgroundColor: AroosiColors.surface,
        borderColor: AroosiColors.primary,
        borderWidth: 2,
        cornerRadius: 16,
        padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
    )
}

@available(iOS 17, *)
public struct AroosiTextAreaStyle {
    public let font: Font
    public let textColor: Color
    public let placeholderFont: Font
    public let placeholderColor: Color
    public let backgroundColor: Color
    public let borderColor: Color
    public let borderWidth: CGFloat
    public let cornerRadius: CGFloat
    public let padding: EdgeInsets
    public let height: CGFloat
    
    public static let `default` = AroosiTextAreaStyle(
        font: AroosiTypography.body(),
        textColor: AroosiColors.text,
        placeholderFont: AroosiTypography.body(),
        placeholderColor: AroosiColors.muted,
        backgroundColor: AroosiColors.surface,
        borderColor: AroosiColors.border,
        borderWidth: 1,
        cornerRadius: 12,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        height: 120
    )
    
    public static let large = AroosiTextAreaStyle(
        font: AroosiTypography.body(size: 16),
        textColor: AroosiColors.text,
        placeholderFont: AroosiTypography.body(size: 16),
        placeholderColor: AroosiColors.muted,
        backgroundColor: AroosiColors.surface,
        borderColor: AroosiColors.border,
        borderWidth: 1,
        cornerRadius: 12,
        padding: EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20),
        height: 200
    )
}

@available(iOS 17, *)
public struct AroosiPickerVisualStyle {
    public let titleFont: Font
    public let titleColor: Color
    public let textColor: Color
    public init(titleFont: Font,
                titleColor: Color,
                textColor: Color) {
        self.titleFont = titleFont
        self.titleColor = titleColor
        self.textColor = textColor
    }
    
    public static let `default` = AroosiPickerVisualStyle(
        titleFont: AroosiTypography.caption(),
        titleColor: AroosiColors.muted,
        textColor: AroosiColors.text
    )
}

@available(iOS 17, *)
public struct AroosiToggleVisualStyle {
    public let titleFont: Font
    public let titleColor: Color
    public let descriptionFont: Font
    public let descriptionColor: Color
    public let tintColor: Color
    public let backgroundColor: Color
    public let padding: EdgeInsets
    public let cornerRadius: CGFloat
    
    public static let `default` = AroosiToggleVisualStyle(
        titleFont: AroosiTypography.body(),
        titleColor: AroosiColors.text,
        descriptionFont: AroosiTypography.caption(),
        descriptionColor: AroosiColors.muted,
        tintColor: AroosiColors.primary,
        backgroundColor: AroosiColors.surface,
        padding: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        cornerRadius: 12
    )
}

@available(iOS 17, *)
public struct AroosiStepperVisualStyle {
    public let titleFont: Font
    public let titleColor: Color
    public let valueFont: Font
    public let valueColor: Color
    public let buttonTextColor: Color
    public let buttonBackgroundColor: Color
    
    public static let `default` = AroosiStepperVisualStyle(
        titleFont: AroosiTypography.body(),
        titleColor: AroosiColors.text,
        valueFont: AroosiTypography.heading(size: 18, weight: .semibold),
        valueColor: AroosiColors.text,
        buttonTextColor: .white,
        buttonBackgroundColor: AroosiColors.primary
    )
}

// MARK: - Custom TextField Style

@available(iOS 17, *)
struct AroosiTextFieldFieldStyle: TextFieldStyle {
    let style: AroosiTextFieldVisualStyle
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(style.font)
            .foregroundStyle(style.textColor)
            .padding(style.padding)
            .background(style.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
    }
}

// MARK: - Validation

@available(iOS 17, *)
public struct ValidationResult {
    public let isValid: Bool
    public let message: String?
    
    public init(isValid: Bool, message: String? = nil) {
        self.isValid = isValid
        self.message = message
    }
}

@available(iOS 17, *)
public protocol ValidationRule {
    func validate(_ input: String) -> ValidationResult
}

@available(iOS 17, *)
public struct EmailValidationRule: ValidationRule {
    public init() {}
    
    public func validate(_ input: String) -> ValidationResult {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if input.isEmpty {
            return ValidationResult(isValid: false, message: "Email is required")
        }
        
        if emailPredicate.evaluate(with: input) {
            return ValidationResult(isValid: true)
        } else {
            return ValidationResult(isValid: false, message: "Please enter a valid email")
        }
    }
}

@available(iOS 17, *)
public struct RequiredValidationRule: ValidationRule {
    public let message: String
    
    public init(message: String = "This field is required") {
        self.message = message
    }
    
    public func validate(_ input: String) -> ValidationResult {
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return ValidationResult(isValid: false, message: message)
        }
        return ValidationResult(isValid: true)
    }
}

@available(iOS 17, *)
public struct MinLengthValidationRule: ValidationRule {
    public let minLength: Int
    public let message: String
    
    public init(minLength: Int, message: String? = nil) {
        self.minLength = minLength
        self.message = message ?? "Must be at least \(minLength) characters"
    }
    
    public func validate(_ input: String) -> ValidationResult {
        if input.count < minLength {
            return ValidationResult(isValid: false, message: message)
        }
        return ValidationResult(isValid: true)
    }
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            AroosiTextField(
                text: .constant(""),
                placeholder: "Enter your name",
                validation: RequiredValidationRule()
            )
            
            AroosiSecureField(
                text: .constant(""),
                placeholder: "Enter your password",
                validation: MinLengthValidationRule(minLength: 8)
            )
            
            AroosiTextArea(
                text: .constant(""),
                placeholder: "Tell us about yourself...",
                validation: RequiredValidationRule()
            )
            
            AroosiToggle(
                isOn: .constant(true),
                title: "Enable notifications",
                description: "Receive updates about new matches"
            )
            
            AroosiStepper(
                value: .constant(25),
                title: "Age"
            )
        }
        .padding()
    }
    .background(AroosiColors.background)
}

#endif
