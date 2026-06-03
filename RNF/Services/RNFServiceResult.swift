import Foundation

enum RNFServiceError: Error, Equatable {
    case unauthenticated
    case networkUnavailable
    case decodingFailed
    case duplicateRecord
    case serverRejected
    case notFound
    case unknown
}

extension RNFServiceError {

    static func from(_ error: Error) -> RNFServiceError {
        if let serviceError = error as? RNFServiceError {
            return serviceError
        }

        if error is AuthProvidingError {
            return .unauthenticated
        }

        return .unknown
    }

}

enum RNFServiceSaveState: Equatable {
    case savedRemotely
    case savedLocallyOnly
    case notSaved
}

struct RNFServiceWriteResult<Value> {
    let value: Value?
    let saveState: RNFServiceSaveState
    let error: RNFServiceError?

    var savedRemotely: Bool {
        saveState == .savedRemotely
    }

    static func savedRemotely(_ value: Value) -> RNFServiceWriteResult<Value> {
        RNFServiceWriteResult(
            value: value,
            saveState: .savedRemotely,
            error: nil
        )
    }

    static func savedLocallyOnly(
        _ value: Value,
        error: RNFServiceError
    ) -> RNFServiceWriteResult<Value> {
        RNFServiceWriteResult(
            value: value,
            saveState: .savedLocallyOnly,
            error: error
        )
    }

    static func notSaved(_ error: RNFServiceError) -> RNFServiceWriteResult<Value> {
        RNFServiceWriteResult(
            value: nil,
            saveState: .notSaved,
            error: error
        )
    }
}
