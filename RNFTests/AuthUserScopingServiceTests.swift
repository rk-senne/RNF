import Foundation
import Supabase
import XCTest
@testable import RNF

final class AuthUserScopingServiceTests: XCTestCase {

    override func tearDown() {
        AuthScopingMockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testDailyLogFetchUsesAuthenticatedUserScope() async throws {
        let userId = UUID()
        var requests: [URLRequest] = []

        AuthScopingMockURLProtocol.requestHandler = { request in
            requests.append(request)
            return Self.jsonResponse(for: request, body: "[]")
        }

        let service = DailyLogService(
            supabase: makeSupabaseService(),
            authProvider: StaticAuthProvider(userId: userId)
        )

        _ = try await service.fetchTodayLog(date: Date())

        let request = try XCTUnwrap(requests.first)
        XCTAssertTrue(request.url?.absoluteString.contains("daily_logs") ?? false)
        XCTAssertTrue(request.url?.absoluteString.contains("user_id=eq.\(userId.uuidString)") ?? false)
    }

    func testChallengeFetchUsesAuthenticatedUserScope() async throws {
        let userId = UUID()
        var requests: [URLRequest] = []

        AuthScopingMockURLProtocol.requestHandler = { request in
            requests.append(request)
            return Self.jsonResponse(for: request, body: "[]")
        }

        let service = ChallengeService(
            supabase: makeSupabaseService(),
            authProvider: StaticAuthProvider(userId: userId)
        )

        _ = try await service.getActiveChallenge()

        let request = try XCTUnwrap(requests.first)
        XCTAssertTrue(request.url?.absoluteString.contains("challenges") ?? false)
        XCTAssertTrue(request.url?.absoluteString.contains("user_id=eq.\(userId.uuidString)") ?? false)
        XCTAssertTrue(request.url?.absoluteString.contains("status=eq.active") ?? false)
    }

    func testWorkoutDailyLogUsesAuthenticatedUserScope() async throws {
        let userId = UUID()
        let dailyLogId = UUID()
        var requests: [URLRequest] = []

        AuthScopingMockURLProtocol.requestHandler = { request in
            requests.append(request)
            return Self.jsonResponse(
                for: request,
                body: Self.dailyLogJSON(id: dailyLogId, userId: userId)
            )
        }

        let supabase = makeSupabaseService()
        let service = WorkoutService(
            supabase: supabase,
            dailyLogService: DailyLogService(
                supabase: supabase,
                authProvider: StaticAuthProvider(userId: userId)
            ),
            authProvider: StaticAuthProvider(userId: userId)
        )

        _ = try await service.dailyLogForWorkout(date: Date())

        let request = try XCTUnwrap(requests.first)
        XCTAssertTrue(request.url?.absoluteString.contains("daily_logs") ?? false)
        XCTAssertTrue(request.url?.absoluteString.contains("user_id=eq.\(userId.uuidString)") ?? false)
    }

    func testReadingDailyLogUsesAuthenticatedUserScope() async throws {
        let userId = UUID()
        let dailyLogId = UUID()
        var requests: [URLRequest] = []

        AuthScopingMockURLProtocol.requestHandler = { request in
            requests.append(request)
            return Self.jsonResponse(
                for: request,
                body: Self.dailyLogJSON(id: dailyLogId, userId: userId)
            )
        }

        let supabase = makeSupabaseService()
        let service = ReadingService(
            supabase: supabase,
            dailyLogService: DailyLogService(
                supabase: supabase,
                authProvider: StaticAuthProvider(userId: userId)
            ),
            authProvider: StaticAuthProvider(userId: userId)
        )

        _ = try await service.dailyLogForReading(date: Date())

        let request = try XCTUnwrap(requests.first)
        XCTAssertTrue(request.url?.absoluteString.contains("daily_logs") ?? false)
        XCTAssertTrue(request.url?.absoluteString.contains("user_id=eq.\(userId.uuidString)") ?? false)
    }

    func testUserServiceTokenFetchUsesAuthenticatedUserScope() async throws {
        let userId = UUID()
        var requests: [URLRequest] = []

        AuthScopingMockURLProtocol.requestHandler = { request in
            requests.append(request)
            return Self.jsonResponse(
                for: request,
                body: #"[{"forgiveness_tokens":3}]"#
            )
        }

        let service = UserService(
            supabase: makeSupabaseService(),
            authProvider: StaticAuthProvider(userId: userId)
        )

        let tokens = try await service.fetchForgivenessTokens()

        XCTAssertEqual(tokens, 3)
        let request = try XCTUnwrap(requests.first)
        XCTAssertTrue(request.url?.absoluteString.contains("users") ?? false)
        XCTAssertTrue(request.url?.absoluteString.contains("id=eq.\(userId.uuidString)") ?? false)
    }

    private func makeSupabaseService() -> SupabaseService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AuthScopingMockURLProtocol.self]

        let session = URLSession(configuration: configuration)
        let options = SupabaseClientOptions(
            global: .init(session: session)
        )
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://example.supabase.co")!,
            supabaseKey: "test-key",
            options: options
        )

        return SupabaseService(client: client)
    }

    private static func jsonResponse(
        for request: URLRequest,
        body: String
    ) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!

        return (response, Data(body.utf8))
    }

    private static func dailyLogJSON(id: UUID, userId: UUID) -> String {
        """
        [
          {
            "id": "\(id.uuidString)",
            "user_id": "\(userId.uuidString)",
            "date": "2026-03-10T00:00:00Z",
            "habits_completed": 1,
            "habits_required": 2,
            "workout_completed": false,
            "reading_completed": false,
            "forgiveness_used": false,
            "xp_earned": 10,
            "status": "partial",
            "created_at": null
          }
        ]
        """
    }

}

private struct StaticAuthProvider: AuthProviding {
    let userId: UUID?

    var currentUserID: UUID? {
        get async {
            userId
        }
    }
}

private final class AuthScopingMockURLProtocol: URLProtocol {

    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

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
