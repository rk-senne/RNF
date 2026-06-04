import Foundation
import Supabase
import XCTest
@testable import RNF

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

    func testFetchTodayLogQueriesNormalizedDate() async throws {
        let userId = UUID()
        let inputDate = Self.date("2026-03-10T15:45:30Z")
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
        _ = try await service.fetchTodayLog(userId: userId, date: inputDate)

        let request = try XCTUnwrap(requests.first)
        let dateFilter = try XCTUnwrap(Self.queryValue(named: "date", in: request))
        let normalizedDateString = String(dateFilter.dropFirst("eq.".count))
        let queriedDate = try XCTUnwrap(Self.date(from: normalizedDateString))

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertTrue(dateFilter.hasPrefix("eq."))
        XCTAssertEqual(queriedDate, Calendar.current.startOfDay(for: inputDate))
    }

    func testFetchTodayLogUsesInjectedDayBoundaryCalendar() async throws {
        let userId = UUID()
        let inputDate = Self.date("2026-03-10T22:30:00Z")
        let calendar = Self.calendar(timeZoneOffset: 7_200)
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

        let service = DailyLogService(
            supabase: makeSupabaseService(),
            calendar: calendar
        )
        _ = try await service.fetchTodayLog(userId: userId, date: inputDate)

        let request = try XCTUnwrap(requests.first)
        let dateFilter = try XCTUnwrap(Self.queryValue(named: "date", in: request))
        let normalizedDateString = String(dateFilter.dropFirst("eq.".count))
        let queriedDate = try XCTUnwrap(Self.date(from: normalizedDateString))

        XCTAssertEqual(
            queriedDate,
            DayBoundaryPolicy.normalizedDay(for: inputDate, calendar: calendar)
        )
    }

    func testSaveDailyLogSurfacesLocalOnlyResultWhenRemoteSaveFails() async throws {
        let userId = UUID()
        var requests: [URLRequest] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Self.jsonData(#"{"message":"daily log save failed"}"#))
        }

        let service = DailyLogService(supabase: makeSupabaseService())
        let dailyLog = DailyLog(
            id: UUID(),
            user_id: userId,
            date: Date(timeIntervalSince1970: 1_772_582_400),
            habits_completed: 1,
            habits_required: 2,
            workout_completed: false,
            reading_completed: false,
            forgiveness_used: false,
            xp_earned: 25,
            status: .partial,
            created_at: nil
        )

        let result = await service.saveDailyLog(dailyLog)

        XCTAssertEqual(result.saveState, .savedLocallyOnly)
        XCTAssertEqual(result.error, .unknown)
        XCTAssertEqual(result.value?.id, dailyLog.id)
        XCTAssertEqual(requests.map(\.httpMethod), ["POST"])
        XCTAssertTrue(requests[0].url?.absoluteString.contains("daily_logs") ?? false)
    }

    func testSaveDailyLogReturnsLocalOnlyWithoutBackendForPlaceholderLog() async throws {
        var requestCount = 0

        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Self.jsonData("{}"))
        }

        let service = DailyLogService(supabase: makeSupabaseService())
        let dailyLog = DailyLog.today(goal: 2)

        let result = await service.saveDailyLog(dailyLog)

        XCTAssertEqual(result.saveState, .savedLocallyOnly)
        XCTAssertEqual(result.error, .unauthenticated)
        XCTAssertEqual(result.value?.id, dailyLog.id)
        XCTAssertEqual(requestCount, 0)
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

    private static func date(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string) ?? Date(timeIntervalSince1970: 0)
    }

    private static func date(from string: String) -> Date? {
        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = fractionalFormatter.date(from: string) {
            return date
        }

        return ISO8601DateFormatter().date(from: string)
    }

    private static func calendar(timeZoneOffset: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: timeZoneOffset) ?? .current
        return calendar
    }

    private static func queryValue(named name: String, in request: URLRequest) -> String? {
        guard let url = request.url else {
            return nil
        }

        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
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
