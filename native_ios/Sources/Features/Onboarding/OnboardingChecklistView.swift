import SwiftUI

#if canImport(FirebaseFirestore)

@available(iOS 17.0.0, *)
public struct OnboardingChecklistView: View {
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @State private var checklistItems: [ChecklistItem] = [
        ChecklistItem(title: "Upload a profile photo"),
        ChecklistItem(title: "Share a short bio"),
        ChecklistItem(title: "Select your interests"),
        ChecklistItem(title: "Complete cultural assessment")
    ]
    
    let onComplete: () -> Void
    
    private var isComplete: Bool {
        checklistItems.allSatisfy { $0.completed }
    }
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: AroosiSpacing.lg) {
                        // Welcome Card
                        welcomeCard
                            .padding(.horizontal, AroosiSpacing.lg)
                            .padding(.top, AroosiSpacing.lg)
                        
                        // Checklist Items
                        VStack(spacing: AroosiSpacing.md) {
                            ForEach(Array(checklistItems.enumerated()), id: \.element.id) { index, item in
                                ChecklistTile(
                                    item: $checklistItems[index],
                                    onTap: {
                                        handleItemTap(item: checklistItems[index], index: index)
                                    }
                                )
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .offset(y: 20)),
                                    removal: .opacity
                                ))
                                .animation(
                                    AroosiMotionCurves.spring
                                        .delay(Double(index) * AroosiMotionDurations.instant),
                                    value: checklistItems[index].completed
                                )
                            }
                        }
                        .padding(.horizontal, AroosiSpacing.lg)
                    }
                    .padding(.bottom, AroosiSpacing.xl)
                }
                
                // Continue Button
                VStack(spacing: AroosiSpacing.md) {
                    Divider()
                    
                    Button(action: {
                        if isComplete {
                            onComplete()
                        }
                    }) {
                        Text(isComplete ? "Continue to Dashboard" : "Complete All Steps")
                            .font(AroosiTypography.body(weight: .semibold, size: 16))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AroosiSpacing.md)
                            .background(isComplete ? AroosiColors.primary : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                    }
                    .disabled(!isComplete)
                    .padding(.horizontal, AroosiSpacing.lg)
                    .padding(.bottom, AroosiSpacing.md)
                }
                .background(AroosiColors.surfaceSecondary)
            }
            .navigationTitle("Complete Your Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .background(AroosiColors.background)
        }
    }
    
    private var welcomeCard: some View {
        VStack(spacing: AroosiSpacing.md) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white)
            
            Text("Welcome to Aroosi!")
                .font(AroosiTypography.heading(.h3))
                .foregroundStyle(.white)
            
            Text("Complete these steps to find culturally compatible matches")
                .font(AroosiTypography.body())
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(AroosiSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    AroosiColors.primary,
                    AroosiColors.primaryDark
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
    
    private func handleItemTap(item: ChecklistItem, index: Int) {
        if item.title == "Complete cultural assessment" {
            // Navigate to cultural assessment
            coordinator.pendingRoute = .dashboard(.culturalMatching)
            coordinator.navigate(to: .dashboard)
        } else {
            // Toggle completion
            withAnimation(AroosiMotionCurves.spring) {
                checklistItems[index].completed.toggle()
            }
        }
    }
}

// MARK: - Checklist Item Model

struct ChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    var completed: Bool = false
}

// MARK: - Checklist Tile Component

@available(iOS 17.0.0, *)
private struct ChecklistTile: View {
    @Binding var item: ChecklistItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AroosiSpacing.md) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(
                            item.completed ? AroosiColors.primary : AroosiColors.borderPrimary,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)
                    
                    if item.completed {
                        Circle()
                            .fill(AroosiColors.primary)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .animation(AroosiMotionCurves.spring, value: item.completed)
                
                // Title
                Text(item.title)
                    .font(AroosiTypography.body(weight: .semibold))
                    .foregroundStyle(item.completed ? AroosiColors.primary : AroosiColors.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Arrow for cultural assessment
                if item.title == "Complete cultural assessment" {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AroosiColors.primary)
                }
            }
            .padding(AroosiSpacing.md)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        item.completed ? AroosiColors.primary : AroosiColors.borderPrimary,
                        lineWidth: item.completed ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

@available(iOS 17.0.0, *)
#Preview {
    OnboardingChecklistView(onComplete: {
        // Onboarding complete
    })
}

#endif
