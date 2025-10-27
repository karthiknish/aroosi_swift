import Foundation

public struct AnalyticsEvent: Equatable {
    public let name: String
    public let parameters: [String: String]

    public init(name: String, parameters: [String: String] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}

public protocol AnalyticsDestination: AnyObject {
    func track(event: AnalyticsEvent)
    func setUserID(_ userID: String?)
    func setUserProperty(_ value: String?, for key: String)
}

@available(iOS 17, *)
public final class AnalyticsService {
    public static let shared = AnalyticsService()

    private var destinations: [WeakDestination] = []
    private let queue = DispatchQueue(label: "com.aroosi.swift.analytics", qos: .utility)
    private let logger = Logger.shared

    private init() {}

    public func addDestination(_ destination: AnalyticsDestination) {
        queue.sync {
            destinations.append(WeakDestination(value: destination))
            purgeDestinations()
        }
    }

    public func removeDestination(_ destination: AnalyticsDestination) {
        queue.sync {
            destinations.removeAll { $0.value === destination || $0.value == nil }
        }
    }

    public func track(_ event: AnalyticsEvent) {
        queue.sync {
            purgeDestinations()
            destinations.forEach { $0.value?.track(event: event) }
        }
        logger.info("Analytics Event → \(event.name) :: \(event.parameters)")
    }

    public func setUserID(_ userID: String?) {
        queue.sync {
            purgeDestinations()
            destinations.forEach { $0.value?.setUserID(userID) }
        }
    }

    public func setUserProperty(_ value: String?, for key: String) {
        queue.sync {
            purgeDestinations()
            destinations.forEach { $0.value?.setUserProperty(value, for: key) }
        }
    }

    private func purgeDestinations() {
        destinations.removeAll { $0.value == nil }
    }

    private struct WeakDestination {
        weak var value: AnalyticsDestination?
    }
}

@available(iOS 17, *)
public final class ConsoleAnalyticsDestination: AnalyticsDestination {
    private let logger = Logger.shared

    public init() {}

    public func track(event: AnalyticsEvent) {
        logger.info("[ConsoleAnalytics] Event: \(event.name) params: \(event.parameters)")
    }

    public func setUserID(_ userID: String?) {
        logger.info("[ConsoleAnalytics] UserID set: \(userID ?? "nil")")
    }

    public func setUserProperty(_ value: String?, for key: String) {
        logger.info("[ConsoleAnalytics] UserProperty → \(key): \(value ?? "nil")")
    }
}
