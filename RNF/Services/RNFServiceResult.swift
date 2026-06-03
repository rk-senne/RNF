import Foundation

enum RNFServiceError: Error {
    case unauthenticated
    case networkUnavailable
    case decodingFailed
    case duplicateRecord
    case serverRejected
    case notFound
    case unknown
}

enum RNFServiceSaveState {
    case savedRemotely
    case savedLocallyOnly
    case notSaved
}

struct RNFServiceWriteResult<Value> {
    let value: Value?
    let saveState: RNFServiceSaveState
    let error: RNFServiceError?

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
