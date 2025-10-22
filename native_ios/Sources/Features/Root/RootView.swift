#if os(iOS)
import SwiftUI

@available(iOS 17, *)
public struct RootView: View {
    @StateObject private var viewModel = RootViewModel()

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
            }
        }
        .task {
            await viewModel.bootstrap()
        }
    }
}

@available(iOS 17, *)
private struct SignedInHomeView: View {
    let user: UserProfile

    var body: some View {
        TabView {
            MatchesView(user: user)
                .tabItem {
                    Label("Matches", systemImage: "heart.fill")
                }

            ProfileView(user: user)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }

            SettingsView(user: user)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}

#Preview {
    RootView()
}
#endif
