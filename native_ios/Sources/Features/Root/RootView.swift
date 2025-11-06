#if os(iOS)
import SwiftUI
import Combine

@available(iOS 17, *)
public struct RootView: View {
    @StateObject private var viewModel = RootViewModel()
    @StateObject private var coordinator = NavigationCoordinator()

    public init() {}

    public var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .progressViewStyle(.circular)
            case .signedOut:
                OnboardingView(onComplete: viewModel.handleOnboardingComplete)
            case .signedIn(let session):
                SignedInHomeView(session: session)
                    .environmentObject(coordinator)
            }
        }
        .task {
            await viewModel.bootstrap()
        }
        .onReceive(viewModel.$state) { newState in
            if case .signedOut = newState {
                coordinator.clearRoute()
                coordinator.navigate(to: .dashboard)
            }
        }
        .preferredColorScheme(.light) // Force light mode
    }
}

@available(iOS 17, *)
private struct SignedInHomeView: View {
    let session: RootViewModel.Session
    @EnvironmentObject private var coordinator: NavigationCoordinator

    private var user: UserProfile { session.user }
    private var hasAdminAccess: Bool { session.capabilities.canAccessAdmin }

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            DashboardView(user: user)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
                .tag(NavigationCoordinator.Tab.dashboard)

            HomeView(user: user)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(NavigationCoordinator.Tab.home)

            MatchesView(user: user)
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }
                .tag(NavigationCoordinator.Tab.matches)

            ProfileView(user: user)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(NavigationCoordinator.Tab.profile)

            SettingsView(user: user)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(NavigationCoordinator.Tab.settings)

            if hasAdminAccess {
                AdminDashboardView(user: user)
                    .tabItem {
                        Label("Admin", systemImage: "building.2")
                    }
                    .tag(NavigationCoordinator.Tab.admin)
            }
        }
        .onAppear { ensureValidSelection() }
        .onChange(of: hasAdminAccess) { _ in ensureValidSelection() }
        .onChange(of: coordinator.selectedTab) { _ in ensureValidSelection() }
        .animation(.easeInOut(duration: AroosiMotionDurations.medium), value: coordinator.selectedTab)
        .toastContainer() // Add toast container for global notifications
    }

    private func ensureValidSelection() {
        if !hasAdminAccess && coordinator.selectedTab == .admin {
            coordinator.navigate(to: .dashboard)
        }
    }
}

#Preview {
    RootView()
}
#endif
