import Foundation
import Auth

protocol AuthProviding {
    var currentUserID: UUID? { get async }
}

extension AuthService: AuthProviding {

    var currentUserID: UUID? {
        get async {
            try? await restoreSession().user.id
        }
    }

}
