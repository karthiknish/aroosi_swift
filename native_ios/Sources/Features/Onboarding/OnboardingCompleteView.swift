import SwiftUI

#if os(iOS)

@available(iOS 17.0.0, *)
public struct OnboardingCompleteView: View {
    let onContinue: () -> Void
    
    @State private var showContent = false
    
    public init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // Success Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 96))
                        .foregroundStyle(Color.blue)
                }
                
                VStack(spacing: 16) {
                    Text("Your profile looks great")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Jump in to start exploring new connections tailored to your preferences.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Continue Button
                Button(action: onContinue) {
                    Text("Go to Dashboard")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("All Set!")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .background(Color(UIColor.systemBackground))
            .onAppear {
                // Trigger animations
                withAnimation(.easeInOut(duration: 0.6)) {
                    showContent = true
                }
            }
        }
    }
}

#if os(iOS)
@available(iOS 17.0.0, *)
#Preview {
    OnboardingCompleteView(onContinue: {
        // Continue to dashboard
    })
}
#endif
#endif
