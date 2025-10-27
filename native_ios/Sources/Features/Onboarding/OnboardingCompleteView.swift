import SwiftUI

@available(iOS 17.0.0, *)
public struct OnboardingCompleteView: View {
    let onContinue: () -> Void
    
    @State private var showContent = false
    
    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: AroosiSpacing.xl) {
                Spacer()
                
                // Success Icon
                ZStack {
                    Circle()
                        .fill(AroosiColors.primary.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 96))
                        .foregroundStyle(AroosiColors.primary)
                }
                .scaleIn(scale: 0.8, duration: AroosiMotionDurations.medium)
                
                VStack(spacing: AroosiSpacing.md) {
                    Text("Your profile looks great")
                        .font(AroosiTypography.heading(.h2))
                        .multilineTextAlignment(.center)
                        .slideInFromBottom(offset: 20, duration: AroosiMotionDurations.short, delay: 0.15)
                    
                    Text("Jump in to start exploring new connections tailored to your preferences.")
                        .font(AroosiTypography.body())
                        .foregroundStyle(AroosiColors.muted)
                        .multilineTextAlignment(.center)
                        .slideInFromBottom(offset: 20, duration: AroosiMotionDurations.short, delay: 0.22)
                }
                .padding(.horizontal, AroosiSpacing.xl)
                
                Spacer()
                
                // Continue Button
                Button(action: onContinue) {
                    Text("Go to Dashboard")
                        .font(AroosiTypography.body(weight: .semibold, size: 16))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AroosiColors.primary)
                        .cornerRadius(12)
                }
                .scaleIn(scale: 0.9, duration: AroosiMotionDurations.medium, delay: 0.3)
                .padding(.horizontal, AroosiSpacing.lg)
                .padding(.bottom, AroosiSpacing.lg)
            }
            .navigationTitle("All Set!")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .background(AroosiColors.background)
            .onAppear {
                // Trigger animations
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showContent = true
                }
            }
        }
    }
}

// MARK: - Preview

@available(iOS 17.0.0, *)
#Preview {
    OnboardingCompleteView(onContinue: {
        // Continue to dashboard
    })
}
