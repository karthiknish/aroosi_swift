import Foundation

public enum RepositoryError: Error, Equatable {
    case notFound
    case invalidData
    case permissionDenied
    case networkFailure
    case alreadyExists
    case unknown
}
