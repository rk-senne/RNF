import Foundation
@testable import RNF

struct StaticTestAuthProvider: AuthProviding {
    let userId: UUID?

    var currentUserID: UUID? {
        get async {
            userId
        }
    }
}
