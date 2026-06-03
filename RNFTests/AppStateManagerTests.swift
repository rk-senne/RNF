import Foundation
import Supabase
import XCTest
@testable import RNF

@MainActor
final class AppStateManagerTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testResolveLaunchStateRoutesToLoggedOutWhenSessionIsMissing() async {
        let supabase = makeSupabaseService()
        let manager = makeAppStateManager(supabase: supabase)

        MockURLProtocol.requestHandler = { request in
            (Self.response(for: request), Self.jsonData("{}"))
        }
        try? await supabase.client.auth.signOut(scope: .local)
        MockURLProtocol.requestHandler = nil

        await manager.resolveLaunchState(date: Self.date("2026-06-08T00:00:00Z"))

        XCTAssertEqual(manager.state, .loggedOut)
    }

    func testResolveLaunchStateRoutesToOnboardingNotificationsWhenChallengeIsMissing() async throws {
        let userId = Self.userId
        let supabase = makeSupabaseService()
        let manager = makeAppStateManager(supabase: supabase)
        var requests: [URLRequest] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)

            let response = Self.response(for: request)
            let url = request.url?.absoluteString ?? ""

            if url.contains("/auth/v1/user") {
                return (response, Self.jsonData(Self.userJSON(id: userId)))
            }

            return (response, Self.jsonData("[]"))
        }

        try await setSession(on: supabase)
        requests.removeAll()

        await manager.resolveLaunchState(date: Self.date("2026-06-08T00:00:00Z"))

        XCTAssertEqual(manager.state, .onboardingNotifications)
        XCTAssertEqual(requests.map(\.httpMethod), ["GET"])
        XCTAssertTrue(requests[0].url?.absoluteString.contains("challenges") ?? false)
    }

    func testResolveLaunchStateRoutesToAuthenticatedWhenChallengeLookupFailsAfterSessionRestore() async throws {
        let userId = Self.userId
        let supabase = makeSupabaseService()
        let manager = makeAppStateManager(supabase: supabase)

        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""

            if url.contains("/auth/v1/user") {
                return (Self.response(for: request), Self.jsonData(Self.userJSON(id: userId)))
            }

            return (
                Self.response(for: request, statusCode: 500),
                Self.jsonData(#"{"message":"challenge lookup failed"}"#)
            )
        }

        try await setSession(on: supabase)

        await manager.resolveLaunchState(date: Self.date("2026-06-08T00:00:00Z"))

        XCTAssertEqual(manager.state, .authenticated)
    }

    func testResolveLaunchStateRoutesToDailyProgressWhenChallengeAndDailyLogExist() async throws {
        let userId = Self.userId
        let challengeId = UUID()
        let dailyLogId = UUID()
        let supabase = makeSupabaseService()
        let manager = makeAppStateManager(supabase: supabase)
        var requests: [URLRequest] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)

            let response = Self.response(for: request)
            let url = request.url?.absoluteString ?? ""

            if url.contains("/auth/v1/user") {
                return (response, Self.jsonData(Self.userJSON(id: userId)))
            }

            if url.contains("challenges") {
                return (
                    response,
                    Self.jsonData(
                        "[\(Self.challengeJSON(id: challengeId, userId: userId, currentDay: 12, status: "active"))]"
                    )
                )
            }

            return (
                response,
                Self.jsonData(
                    "[\(Self.dailyLogJSON(id: dailyLogId, userId: userId, status: "partial"))]"
                )
            )
        }

        try await setSession(on: supabase)
        requests.removeAll()

        await manager.resolveLaunchState(date: Self.date("2026-06-08T00:00:00Z"))

        XCTAssertEqual(manager.state, .dailyProgress)
        XCTAssertEqual(requests.map(\.httpMethod), ["GET", "GET"])
        XCTAssertTrue(requests[0].url?.absoluteString.contains("challenges") ?? false)
        XCTAssertTrue(requests[1].url?.absoluteString.contains("daily_logs") ?? false)
    }

    func testOnboardingTransitionsRouteFromNotificationsToCommitmentToChallengeActive() {
        let supabase = makeSupabaseService()
        let manager = AppStateManager(
            initialState: .onboardingNotifications,
            supabase: supabase,
            challengeService: ChallengeService(supabase: supabase),
            dailyLogService: DailyLogService(supabase: supabase)
        )

        manager.completeNotificationSetup()

        XCTAssertEqual(manager.state, .onboardingCommitment)

        manager.confirmCommitment()

        XCTAssertEqual(manager.state, .challengeActive)
    }

    private func makeAppStateManager(supabase: SupabaseService) -> AppStateManager {
        AppStateManager(
            initialState: .authenticated,
            supabase: supabase,
            challengeService: ChallengeService(supabase: supabase),
            dailyLogService: DailyLogService(supabase: supabase)
        )
    }

    private func makeSupabaseService() -> SupabaseService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]

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

    private func setSession(on supabase: SupabaseService) async throws {
        try await supabase.client.auth.setSession(
            accessToken: Self.accessToken,
            refreshToken: "dummy-refresh-token"
        )
    }

    private static let userId = UUID(uuidString: "f33d3ec9-a2ee-47c4-80e1-5bd919f3d8b8")!

    private static let accessToken =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjo0ODUyMTYzNTkzLCJzdWIiOiJmMzNkM2VjOS1hMmVlLTQ3YzQtODBlMS01YmQ5MTlmM2Q4YjgiLCJlbWFpbCI6ImhpQGJpbmFyeXNjcmFwaW5nLmNvIiwicGhvbmUiOiIiLCJhcHBfbWV0YWRhdGEiOnsicHJvdmlkZXIiOiJlbWFpbCIsInByb3ZpZGVycyI6WyJlbWFpbCJdfSwidXNlcl9tZXRhZGF0YSI6e30sInJvbGUiOiJhdXRoZW50aWNhdGVkIn0.UiEhoahP9GNrBKw_OHBWyqYudtoIlZGkrjs7Qa8hU7I"

    private static func response(for request: URLRequest, statusCode: Int = 200) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }

    private static func jsonData(_ string: String) -> Data {
        Data(string.utf8)
    }

    private static func date(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string) ?? Date(timeIntervalSince1970: 0)
    }

    private static func userJSON(id: UUID) -> String {
        """
        {
          "id": "\(id.uuidString)",
          "aud": "authenticated",
          "role": "authenticated",
          "email": "test@example.com",
          "phone": "",
          "app_metadata": {
            "provider": "email",
            "providers": ["email"]
          },
          "user_metadata": {},
          "created_at": "2026-03-10T00:00:00Z",
          "updated_at": "2026-03-10T00:00:00Z"
        }
        """
    }

    private static func challengeJSON(
        id: UUID,
        userId: UUID,
        currentDay: Int,
        status: String
    ) -> String {
        """
        {
          "id": "\(id.uuidString)",
          "user_id": "\(userId.uuidString)",
          "start_date": "2026-03-10T00:00:00Z",
          "end_date": "2026-06-08T00:00:00Z",
          "current_day": \(currentDay),
          "status": "\(status)",
          "created_at": null
        }
        """
    }

    private static func dailyLogJSON(
        id: UUID,
        userId: UUID,
        status: String
    ) -> String {
        """
        {
          "id": "\(id.uuidString)",
          "user_id": "\(userId.uuidString)",
          "date": "2026-06-08T00:00:00Z",
          "habits_completed": 1,
          "habits_required": 2,
          "workout_completed": false,
          "reading_completed": false,
          "forgiveness_used": false,
          "xp_earned": 0,
          "status": "\(status)",
          "created_at": null
        }
        """
    }

}

private final class MockURLProtocol: URLProtocol {

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
