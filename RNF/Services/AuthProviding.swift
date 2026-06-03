import Foundation
import Auth

protocol AuthProviding {
    var currentUserID: UUID? { get async }
}

enum AuthProvidingError: Error {
    case missingCurrentUser
}

extension AuthProviding {

    func requireCurrentUserID() async throws -> UUID {
        guard let currentUserID = await currentUserID else {
            throw AuthProvidingError.missingCurrentUser
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
