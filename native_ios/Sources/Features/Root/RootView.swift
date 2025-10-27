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
            case .signedIn(let user):
                SignedInHomeView(user: user)
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
    let user: UserProfile
    @EnvironmentObject private var coordinator: NavigationCoordinator

    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            DashboardView(user: user)
                .tabItem {
                    Label("Home", systemImage: "square.grid.2x2")
                }
                .tag(NavigationCoordinator.Tab.dashboard)

            SearchView(user: user)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(NavigationCoordinator.Tab.search)

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
        }
        .animation(.easeInOut(duration: AroosiMotionDurations.medium), value: coordinator.selectedTab)
        .toastContainer() // Add toast container for global notifications
    }

#Preview {
    RootView()
}
#endif
