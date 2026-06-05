import Foundation
import Auth

protocol AuthProviding {
    var currentUserID: UUID? { get async }
}

enum AuthProvidingError: Error {
    case missingCurrentUser
    case userIdMismatch
}

extension AuthProviding {

    func requireCurrentUserID() async throws -> UUID {
        guard let currentUserID = await currentUserID else {
            throw AuthProvidingError.missingCurrentUser
        }

        return currentUserID
    }

    func requireCurrentUserID(matching userId: UUID) async throws -> UUID {
        let currentUserID = try await requireCurrentUserID()
        guard currentUserID == userId else {
            throw AuthProvidingError.userIdMismatch
        }

        return currentUserID
    }

}

extension AuthService: AuthProviding {

    var currentUserID: UUID? {
        get async {
            try? await restoreSession().user.id
        }
    }

}
