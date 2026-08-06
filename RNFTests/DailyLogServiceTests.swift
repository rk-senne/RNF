import Foundation
import Supabase
import XCTest
@testable import RNF

@MainActor
final class DailyLogServiceTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testRecordHabitCompletionReturnsExistingCompletionWithoutInsert() async throws {
        let userId = UUID()
        let habitId = UUID()
        let existingCompletionId = UUID()
        let completionDate = Date(timeIntervalSince1970: 1_772_582_400)
        var requests: [URLRequest] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            return (
                response,
                Self.jsonData(
                    """
                    [
                      {
                        "id": "\(existingCompletionId.uuidString)",
                        "user_id": "\(userId.uuidString)",
                        "habit_id": "\(habitId.uuidString)",
                        "completed_at": "2026-03-10T09:00:00Z",
                        "date": "2026-03-10T00:00:00Z",
                        "xp_awarded": 25,
                        "created_at": null
                      }
                    ]
                    """
                )
            )
        }

        let service = DailyLogService(supabase: makeSupabaseService())
        let result = try await service.recordHabitCompletion(
            HabitCompletion(
                id: UUID(),
                user_id: userId,
                habit_id: habitId,
                completed_at: completionDate,
                date: completionDate,
                xp_awarded: 25
            )
        )

        XCTAssertEqual(result?.id, existingCompletionId)
        XCTAssertEqual(requests.map(\.httpMethod), ["GET"])
        XCTAssertTrue(requests[0].url?.absoluteString.contains("habit_completions") ?? false)
        XCTAssertTrue(requests[0].url?.absoluteString.contains("limit=1") ?? false)
    }

    func testRecordHabitCompletionRefetchesExistingCompletionAfterDuplicateInsertFailure() async throws {
        let userId = UUID()
        let habitId = UUID()
        let existingCompletionId = UUID()
        let completionDate = Date(timeIntervalSince1970: 1_772_582_400)
        var requests: [URLRequest] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)

            let url = request.url!
            let response = HTTPURLResponse(
                url: url,
                statusCode: request.httpMethod == "POST" ? 409 : 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            if request.httpMethod == "POST" {
                return (
                    response,
                    Self.jsonData(#"{"code":"23505","message":"duplicate key value violates unique constraint"}"#)
                )
            }

            let body = requests.count == 1
                ? "[]"
                : """
                  [
                    {
                      "id": "\(existingCompletionId.uuidString)",
                      "user_id": "\(userId.uuidString)",
                      "habit_id": "\(habitId.uuidString)",
                      "completed_at": "2026-03-10T09:00:00Z",
                      "date": "2026-03-10T00:00:00Z",
                      "xp_awarded": 25,
                      "created_at": null
                    }
                  ]
                  """

            return (response, Self.jsonData(body))
        }

        let service = DailyLogService(supabase: makeSupabaseService())
        let result = try await service.recordHabitCompletion(
            HabitCompletion(
                id: UUID(),
                user_id: userId,
                habit_id: habitId,
                completed_at: completionDate,
                date: completionDate,
                xp_awarded: 25
            )
        )

        XCTAssertEqual(result?.id, existingCompletionId)
        XCTAssertEqual(requests.map(\.httpMethod), ["GET", "POST", "GET"])
        XCTAssertTrue(requests[2].url?.absoluteString.contains("habit_completions") ?? false)
    }

    func testRecordHabitCompletionWithoutUserIdDoesNotCallBackend() async throws {
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Self.jsonData("[]"))
        }

        let service = DailyLogService(supabase: makeSupabaseService())
        let result = try await service.recordHabitCompletion(
            HabitCompletion(
                id: UUID(),
                user_id: nil,
                habit_id: UUID(),
                completed_at: Date(),
                date: Date(),
                xp_awarded: 25
            )
        )

        XCTAssertNil(result)
        XCTAssertEqual(requestCount, 0)
    }

    func testUpdateStatusPersistsCompleteStatus() async throws {
        let userId = UUID()
        let dailyLogId = UUID()
        let logDate = Date(timeIntervalSince1970: 1_772_582_400)
        var requests: [URLRequest] = []
        var patchBodies: [Data] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            if request.httpMethod == "GET" {
                return (
                    response,
                    Self.jsonData(
                        Self.dailyLogJSON(
                            id: dailyLogId,
                            userId: userId,
                            date: "2026-03-10T00:00:00Z",
                            habitsCompleted: 2,
                            habitsRequired: 2,
                            workoutCompleted: true,
                            readingCompleted: true,
                            status: "partial",
                            wrappedInArray: true
                        )
                    )
                )
            }

            if let body = Self.requestBodyData(from: request) {
                patchBodies.append(body)
            }

            return (
                response,
                Self.jsonData(
                    Self.dailyLogJSON(
                        id: dailyLogId,
                        userId: userId,
                        date: "2026-03-10T00:00:00Z",
                        habitsCompleted: 2,
                        habitsRequired: 2,
                        workoutCompleted: true,
                        readingCompleted: true,
                        status: "complete"
                    )
                )
            )
        }

        let service = DailyLogService(supabase: makeSupabaseService())
        let result = try await service.updateStatus(userId: userId, date: logDate)

        XCTAssertEqual(result?.id, dailyLogId)
        XCTAssertEqual(result?.status, .complete)
        XCTAssertEqual(requests.map(\.httpMethod), ["GET", "PATCH"])
        XCTAssertTrue(requests[1].url?.absoluteString.contains("daily_logs") ?? false)
        XCTAssertTrue(requests[1].url?.absoluteString.contains("id=eq.\(dailyLogId.uuidString)") ?? false)

        let body = try XCTUnwrap(patchBodies.first)
        let bodyObject = try JSONSerialization.jsonObject(with: body) as? [String: String]
        XCTAssertEqual(bodyObject?["status"], "complete")
    }

    func testUpdateStatusReturnsNilWhenDailyLogIsMissing() async throws {
        var requests: [URLRequest] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Self.jsonData("[]"))
        }

        let service = DailyLogService(supabase: makeSupabaseService())
        let result = try await service.updateStatus(userId: UUID(), date: Date())

        XCTAssertNil(result)
        XCTAssertEqual(requests.map(\.httpMethod), ["GET"])
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

    private static func jsonData(_ string: String) -> Data {
        Data(string.utf8)
    }

    private static func requestBodyData(from request: URLRequest) -> Data? {
        if let body = request.httpBody {
            return body
        }

        guard let stream = request.httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)

        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)

            if count < 0 {
                return nil
            }

            if count == 0 {
                break
            }

            data.append(buffer, count: count)
        }

        return data
    }

    private static func dailyLogJSON(
        id: UUID,
        userId: UUID,
        date: String,
        habitsCompleted: Int,
        habitsRequired: Int,
        workoutCompleted: Bool,
        readingCompleted: Bool,
        status: String,
        wrappedInArray: Bool = false
    ) -> String {
        let object = """
        {
          "id": "\(id.uuidString)",
          "user_id": "\(userId.uuidString)",
          "date": "\(date)",
          "habits_completed": \(habitsCompleted),
          "habits_required": \(habitsRequired),
          "workout_completed": \(workoutCompleted),
          "reading_completed": \(readingCompleted),
          "forgiveness_used": false,
          "xp_earned": 0,
          "status": "\(status)",
          "created_at": null
        }
        """

        return wrappedInArray ? "[\(object)]" : object
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
