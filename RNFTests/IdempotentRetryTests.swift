import Foundation
import Supabase
import XCTest
@testable import RNF

final class IdempotentRetryTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    // MARK: - Workout Idempotency

    func testWorkoutCompleteReturnsSavedWhenAlreadyCompleted() async {
        let userId = UUID()
        let dailyLogId = UUID()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Self.jsonData(Self.dailyLogJSON(
                id: dailyLogId, userId: userId, workoutCompleted: true, readingCompleted: false, wrappedInArray: true
            )))
        }

        let supabase = makeSupabaseService()
        let service = WorkoutService(
            supabase: supabase,
            dailyLogService: DailyLogService(supabase: supabase),
            authProvider: MockAuthProvider(userID: userId)
        )

        let result = await service.completeWorkoutSafe(userId: userId)
        XCTAssertEqual(result.saveState, .savedRemotely)
        XCTAssertEqual(result.value?.workout_completed, true)
        XCTAssertNil(result.error)
    }

    func testWorkoutCompleteReturnsSavedOnFirstCompletion() async {
        let userId = UUID()
        let dailyLogId = UUID()
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            if request.httpMethod == "GET" {
                let completed = requestCount > 2
                return (response, Self.jsonData(Self.dailyLogJSON(
                    id: dailyLogId, userId: userId, workoutCompleted: completed, readingCompleted: false, wrappedInArray: true
                )))
            }

            return (response, Self.jsonData(Self.dailyLogJSON(
                id: dailyLogId, userId: userId, workoutCompleted: true, readingCompleted: false
            )))
        }

        let supabase = makeSupabaseService()
        let service = WorkoutService(
            supabase: supabase,
            dailyLogService: DailyLogService(supabase: supabase),
            authProvider: MockAuthProvider(userID: userId)
        )

        let result = await service.completeWorkoutSafe(userId: userId)
        XCTAssertEqual(result.saveState, .savedRemotely)
        XCTAssertNil(result.error)
    }

    // MARK: - Reading Idempotency

    func testReadingCompleteReturnsSavedWhenAlreadyCompleted() async {
        let userId = UUID()
        let dailyLogId = UUID()

        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Self.jsonData(Self.dailyLogJSON(
                id: dailyLogId, userId: userId, workoutCompleted: false, readingCompleted: true, wrappedInArray: true
            )))
        }

        let supabase = makeSupabaseService()
        let service = ReadingService(
            supabase: supabase,
            dailyLogService: DailyLogService(supabase: supabase),
            authProvider: MockAuthProvider(userID: userId)
        )

        let result = await service.completeReadingSafe(userId: userId)
        XCTAssertEqual(result.saveState, .savedRemotely)
        XCTAssertEqual(result.value?.reading_completed, true)
        XCTAssertNil(result.error)
    }

    // MARK: - Error Handling

    func testWorkoutCompleteReturnsNotSavedOnNetworkError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let supabase = makeSupabaseService()
        let userId = UUID()
        let service = WorkoutService(
            supabase: supabase,
            dailyLogService: DailyLogService(supabase: supabase),
            authProvider: MockAuthProvider(userID: userId)
        )

        let result = await service.completeWorkoutSafe(userId: userId)
        XCTAssertEqual(result.saveState, .notSaved)
        XCTAssertEqual(result.error, .unknown)
    }

    // MARK: - Helpers

    private func makeSupabaseService() -> SupabaseService {
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

    private static func jsonData(_ string: String) -> Data { Data(string.utf8) }

    private static func dailyLogJSON(
        id: UUID, userId: UUID,
        workoutCompleted: Bool, readingCompleted: Bool,
        wrappedInArray: Bool = false
    ) -> String {
        let object = """
        {
          "id": "\(id.uuidString)",
          "user_id": "\(userId.uuidString)",
          "date": "2026-06-15T00:00:00Z",
          "habits_completed": 2,
          "habits_required": 2,
          "workout_completed": \(workoutCompleted),
          "reading_completed": \(readingCompleted),
          "forgiveness_used": false,
          "xp_earned": 0,
          "status": "partial",
          "created_at": null
        }
        """
        return wrappedInArray ? "[\(object)]" : object
    }
}

private struct MockAuthProvider: AuthProviding {
    let userID: UUID?
    var currentUserID: UUID? { get async { userID } }
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
