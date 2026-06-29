import Foundation
import XCTest
@testable import RNF

final class AuthUserScopingTests: XCTestCase {

    // MARK: - AuthProviding Boundary

    func testRequireCurrentUserIDThrowsWhenUnauthenticated() async {
        let provider = MockAuthProvider(userID: nil)
        do {
            _ = try await provider.requireCurrentUserID()
            XCTFail("Expected error")
        } catch {
            XCTAssertTrue(error is AuthProvidingError)
        }
    }

    func testRequireCurrentUserIDReturnsIDWhenAuthenticated() async throws {
        let userId = UUID()
        let provider = MockAuthProvider(userID: userId)
        let result = try await provider.requireCurrentUserID()
        XCTAssertEqual(result, userId)
    }

    // MARK: - WorkoutService User Scoping

    func testWorkoutServiceSafeReturnsUnauthenticatedWhenNoUser() async {
        let service = WorkoutService(
            supabase: makeMockSupabase(),
            authProvider: MockAuthProvider(userID: nil)
        )
        let result = await service.completeWorkoutSafe()
        XCTAssertEqual(result.error, .unauthenticated)
        XCTAssertEqual(result.saveState, .notSaved)
    }

    // MARK: - ReadingService User Scoping

    func testReadingServiceSafeReturnsUnauthenticatedWhenNoUser() async {
        let service = ReadingService(
            supabase: makeMockSupabase(),
            authProvider: MockAuthProvider(userID: nil)
        )
        let result = await service.completeReadingSafe()
        XCTAssertEqual(result.error, .unauthenticated)
        XCTAssertEqual(result.saveState, .notSaved)
    }

    // MARK: - DailyLogService User Scoping

    func testDailyLogServiceAuthenticatedRecordRejectsNilUserId() async throws {
        let service = DailyLogService(supabase: makeMockSupabase())
        let completion = HabitCompletion(
            id: UUID(), user_id: nil, habit_id: UUID(),
            completed_at: Date(), date: Date(), xp_awarded: 10
        )
        let result = try await service.recordHabitCompletion(completion)
        XCTAssertNil(result, "Should reject completion without user_id")
    }

    // MARK: - Helpers

    private func makeMockSupabase() -> SupabaseService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let options = SupabaseClientOptions(global: .init(session: session))
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://example.supabase.co")!,
            supabaseKey: "test-key",
            options: options
        )
        return SupabaseService(client: client)
    }
}

private struct MockAuthProvider: AuthProviding {
    let userID: UUID?
    var currentUserID: UUID? {
        get async { userID }
    }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
