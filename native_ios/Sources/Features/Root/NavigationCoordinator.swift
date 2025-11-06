#if os(iOS)
import Foundation

@available(iOS 17, *)
@MainActor
public final class NavigationCoordinator: ObservableObject {
    public enum Tab: Hashable {
        case dashboard
        case home
        case matches
        case profile
        case settings
        case admin
    }

    public enum Route: Equatable {
        case dashboard(DashboardRoute)
        case home(HomeRoute)
        case matches(MatchesRoute)
        case profile(ProfileRoute)
        case settings(SettingsRoute)

        var tab: Tab {
            switch self {
            case .dashboard: return .dashboard
            case .home: return .home
            case .matches: return .matches
            case .profile: return .profile
            case .settings: return .settings
            }
        }
    }

    public enum DashboardRoute: Equatable, Identifiable {
        case quickPicks
        case culturalMatching
        case icebreakers
        case recentMatches

        public var id: String {
            switch self {
            case .quickPicks: return "dashboard.quickPicks"
            case .culturalMatching: return "dashboard.culturalMatching"
            case .icebreakers: return "dashboard.icebreakers"
            case .recentMatches: return "dashboard.recentMatches"
            }
        }
    }

    public enum HomeRoute: Equatable, Identifiable {
        case overview

        public var id: String {
            "home.overview"
        }
    }

    public enum MatchesRoute: Equatable, Identifiable {
        case conversation(matchID: String, conversationID: String?)
        case shortlist

        public var id: String {
            switch self {
            case .conversation(let matchID, _): return "matches.conversation.\(matchID)"
            case .shortlist: return "matches.shortlist"
            }
        }
    }

    public enum ProfileRoute: Equatable, Identifiable {
        case editProfile
        case favorites
        case shortlist
        case culturalProfile
        case familyApproval

        public var id: String {
            switch self {
            case .editProfile: return "profile.edit"
            case .favorites: return "profile.favorites"
            case .shortlist: return "profile.shortlist"
            case .culturalProfile: return "profile.cultural"
            case .familyApproval: return "profile.familyApproval"
            }
        }
    }

    public enum SettingsRoute: Equatable, Identifiable {
        case contactSupport
        case blockedUsers
        case privacy

        public var id: String {
            switch self {
            case .contactSupport: return "settings.support"
            case .blockedUsers: return "settings.blocked"
            case .privacy: return "settings.privacy"
            }
        }
    }

    @Published public var selectedTab: Tab = .dashboard
    @Published public private(set) var pendingRoute: Route?

    public init() {}

    public func open(_ route: Route) {
        selectedTab = route.tab
        pendingRoute = route
    }

    public func consumePendingRoute(for tab: Tab) -> Route? {
        guard let route = pendingRoute, route.tab == tab else { return nil }
        pendingRoute = nil
        return route
    }

    public func clearRoute() {
        pendingRoute = nil
    }

    public func navigate(to tab: Tab) {
        selectedTab = tab
    }

    public func handle(url: URL) {
        guard let scheme = url.scheme?.lowercased(), scheme == "aroosi" else {
            return
        }

        let pathComponents = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .split(separator: "/")
            .map(String.init)

        guard let first = pathComponents.first else { return }

        switch first.lowercased() {
        case "quick-picks":
            open(.dashboard(.quickPicks))
        case "cultural", "cultural-matching":
            open(.dashboard(.culturalMatching))
        case "icebreakers":
            open(.dashboard(.icebreakers))
        case "matches":
            if pathComponents.count > 1 {
                let matchID = pathComponents[1]
                let conversationID = url.queryItems?["conversation"]
                open(.matches(.conversation(matchID: matchID, conversationID: conversationID)))
            } else {
                navigate(to: .matches)
            }
        case "profile":
            if let action = pathComponents.dropFirst().first?.lowercased() {
                switch action {
                case "edit":
                    open(.profile(.editProfile))
                case "favorites":
                    open(.profile(.favorites))
                case "shortlist":
                    open(.profile(.shortlist))
                case "cultural":
                    open(.profile(.culturalProfile))
                default:
                    navigate(to: .profile)
                }
            } else {
                navigate(to: .profile)
            }
        case "settings":
            if let action = pathComponents.dropFirst().first?.lowercased() {
                switch action {
                case "support":
                    open(.settings(.contactSupport))
                case "blocked", "blocked-users":
                    open(.settings(.blockedUsers))
                case "privacy":
                    open(.settings(.privacy))
                default:
                    navigate(to: .settings)
                }
            } else {
                navigate(to: .settings)
            }
        case "home", "search":
            navigate(to: .home)
        case "admin":
            navigate(to: .admin)
        default:
            break
        }
    }
}

private extension URL {
    var queryItems: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return nil }
        guard let items = components.queryItems, !items.isEmpty else { return nil }
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }
}
#endif
