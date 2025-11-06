import Foundation

public enum LoggerLevel {
    case info
    case error
}

public protocol LoggerSink: AnyObject {
    func log(level: LoggerLevel, message: String)
}

#if os(iOS)
import os

@available(iOS 17, *)
public final class Logger {
    public static let shared = Logger()

    private let logger = os.Logger(subsystem: "com.aroosi.swift", category: "App")
    private var sinks: [WeakSink] = []
    private let sinkQueue = DispatchQueue(label: "com.aroosi.swift.logger.sinks", qos: .utility)

    private init() {}

    public func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
        notifySinks(level: .info, message: message)
    }

    public func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
        notifySinks(level: .error, message: message)
    }

    public func addSink(_ sink: LoggerSink) {
        sinkQueue.sync {
            sinks.append(WeakSink(value: sink))
            purgeDeallocatedSinks()
        }
    }

    public func removeSink(_ sink: LoggerSink) {
        sinkQueue.sync {
            sinks.removeAll { $0.value === sink || $0.value == nil }
        }
    }

    private func notifySinks(level: LoggerLevel, message: String) {
        sinkQueue.sync {
            purgeDeallocatedSinks()
            sinks.forEach { $0.value?.log(level: level, message: message) }
        }
    }

    private func purgeDeallocatedSinks() {
        sinks.removeAll { $0.value == nil }
    }

    private struct WeakSink {
        weak var value: LoggerSink?
    }
}

#else

public final class Logger {
    public static let shared = Logger()

    private init() {}

    public func info(_ message: String) {}

    public func error(_ message: String) {}

    public func addSink(_ sink: LoggerSink) {}

    public func removeSink(_ sink: LoggerSink) {}
}

#endif
