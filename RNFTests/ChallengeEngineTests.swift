import Foundation
import Supabase
import XCTest
@testable import RNF

@MainActor
final class ChallengeEngineTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testAdvanceIfDayCompleteCompletesFinalDayChallenge() async {
        let userId = UUID()
        let challengeId = UUID()
        let dailyLogId = UUID()
        let testDate = Self.date("2026-06-08T00:00:00Z")
        var requests: [URLRequest] = []
        var patchBodies: [Data] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)

            if let body = Self.requestBodyData(from: request) {
                patchBodies.append(body)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let url = request.url?.absoluteString ?? ""

            if request.httpMethod == "GET", url.contains("challenges") {
                return (
                    response,
                    Self.jsonData(
                        "[\(Self.challengeJSON(id: challengeId, userId: userId, currentDay: Challenge.totalDays, status: "active"))]"
                    )
                )
            }

            if request.httpMethod == "GET", url.contains("daily_logs") {
                return (
                    response,
                    Self.jsonData(
                        "[\(Self.dailyLogJSON(id: dailyLogId, userId: userId, status: "partial"))]"
                    )
                )
            }

            if request.httpMethod == "PATCH", url.contains("daily_logs") {
                return (
                    response,
                    Self.jsonData(
                        Self.dailyLogJSON(id: dailyLogId, userId: userId, status: "complete")
                    )
                )
            }

            return (
                response,
                Self.jsonData(
                    Self.challengeJSON(
                        id: challengeId,
                        userId: userId,
                        currentDay: Challenge.totalDays,
                        status: "completed"
                    )
                )
            )
        }

        let engine = makeChallengeEngine()
        let result = await engine.advanceIfDayComplete(userId: userId, date: testDate)

        XCTAssertEqual(result?.id, challengeId)
        XCTAssertEqual(result?.status, .completed)
        XCTAssertEqual(requests.map(\.httpMethod), ["GET", "GET", "PATCH", "PATCH"])
        XCTAssertTrue(requests[3].url?.absoluteString.contains("challenges") ?? false)

        let completionBody = patchBodies.last.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: String] }
        XCTAssertEqual(completionBody?["status"], "completed")
    }

    func testAdvanceIfDayCompleteUsesNormalizedChallengeStartDayBoundary() async {
        let userId = UUID()
        let challengeId = UUID()
        let dailyLogId = UUID()
        let challengeStartDate = "2026-03-10T23:30:00Z"
        let testDate = Self.date("2026-03-10T00:05:00Z")
        var requests: [URLRequest] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let url = request.url?.absoluteString ?? ""

            if request.httpMethod == "GET", url.contains("challenges") {
                return (
                    response,
                    Self.jsonData(
                        "[\(Self.challengeJSON(id: challengeId, userId: userId, currentDay: 1, status: "active", startDate: challengeStartDate))]"
                    )
                )
            }

            if request.httpMethod == "GET", url.contains("daily_logs") {
                return (
                    response,
                    Self.jsonData(
                        "[\(Self.dailyLogJSON(id: dailyLogId, userId: userId, status: "partial"))]"
                    )
                )
            }

            if request.httpMethod == "PATCH", url.contains("daily_logs") {
                return (
                    response,
                    Self.jsonData(
                        Self.dailyLogJSON(id: dailyLogId, userId: userId, status: "complete")
                    )
                )
            }

            return (
                response,
                Self.jsonData(
                    Self.challengeJSON(
                        id: challengeId,
                        userId: userId,
                        currentDay: 2,
                        status: "active",
                        startDate: challengeStartDate
                    )
                )
            )
        }

        let engine = makeChallengeEngine(calendar: Self.gmtCalendar())
        let result = await engine.advanceIfDayComplete(userId: userId, date: testDate)

        XCTAssertEqual(result?.id, challengeId)
        XCTAssertEqual(result?.current_day, 2)
        XCTAssertEqual(requests.map(\.httpMethod), ["GET", "GET", "PATCH", "PATCH"])
        XCTAssertTrue(requests[1].url?.absoluteString.contains("daily_logs") ?? false)
    }

    func testRestartChallengeResetsCompletedChallengeAndStartsNewChallenge() async {
        let userId = UUID()
        let completedChallengeId = UUID()
        let restartedChallengeId = UUID()
        let startDate = Self.date("2026-06-09T00:00:00Z")
        var requests: [URLRequest] = []
        var requestBodies: [Data] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)

            if let body = Self.requestBodyData(from: request) {
                requestBodies.append(body)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            if request.httpMethod == "PATCH" {
                return (
                    response,
                    Self.jsonData(
                        Self.challengeJSON(
                            id: completedChallengeId,
                            userId: userId,
                            currentDay: Challenge.totalDays,
                            status: "reset"
                        )
                    )
                )
            }

            return (
                response,
                Self.jsonData(
                    Self.challengeJSON(
                        id: restartedChallengeId,
                        userId: userId,
                        currentDay: 1,
                        status: "active"
                    )
                )
            )
        }

        let engine = makeChallengeEngine()
        let result = await engine.restartChallenge(
            Challenge(
                id: completedChallengeId,
                user_id: userId,
                start_date: Date(timeIntervalSince1970: 1_772_582_400),
                end_date: Date(timeIntervalSince1970: 1_780_272_000),
                current_day: Challenge.totalDays,
                status: .completed,
                created_at: nil
            ),
            startDate: startDate
        )

        XCTAssertEqual(result?.id, restartedChallengeId)
        XCTAssertEqual(result?.current_day, 1)
        XCTAssertEqual(result?.status, .active)
        XCTAssertEqual(requests.map(\.httpMethod), ["PATCH", "POST"])
        XCTAssertTrue(requests[0].url?.absoluteString.contains("challenges") ?? false)
        XCTAssertTrue(requests[0].url?.absoluteString.contains("id=eq.\(completedChallengeId.uuidString)") ?? false)

        let resetBody = requestBodies.first.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: String] }
        XCTAssertEqual(resetBody?["status"], "reset")
    }

    func testUseForgivenessDecrementsTokenAndPreservesStreak() async {
        let userId = UUID()
        let dailyLogId = UUID()
        let date = Self.date("2026-06-08T00:00:00Z")
        var requests: [URLRequest] = []
        var requestBodies: [Data] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)

            if let body = Self.requestBodyData(from: request) {
                requestBodies.append(body)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            let url = request.url?.absoluteString ?? ""

            if request.httpMethod == "GET", url.contains("daily_logs") {
                return (
                    response,
                    Self.jsonData(
                        "[\(Self.dailyLogJSON(id: dailyLogId, userId: userId, status: "missed", habitsCompleted: 0, workoutCompleted: false, readingCompleted: false))]"
                    )
                )
            }

            if request.httpMethod == "PATCH", url.contains("daily_logs") {
                return (
                    response,
                    Self.jsonData(
                        Self.dailyLogJSON(
                            id: dailyLogId,
                            userId: userId,
                            status: "missed",
                            habitsCompleted: 0,
                            workoutCompleted: false,
                            readingCompleted: false
                        )
                    )
                )
            }

            if request.httpMethod == "GET", url.contains("users") {
                return (response, Self.jsonData(#"[{"forgiveness_tokens":1}]"#))
            }

            if request.httpMethod == "PATCH", url.contains("users") {
                return (response, Self.jsonData(#"{"forgiveness_tokens":0}"#))
            }

            return (response, Self.jsonData("{}"))
        }

        let engine = makeChallengeEngine()
        let result = await engine.useForgiveness(
            userId: userId,
            date: date,
            currentStreak: 12
        )

        XCTAssertEqual(result?.dailyLog.id, dailyLogId)
        XCTAssertEqual(result?.dailyLog.status, .forgiven)
        XCTAssertEqual(result?.dailyLog.forgiveness_used, true)
        XCTAssertEqual(result?.remainingTokens, 0)
        XCTAssertEqual(result?.preservedStreak, 12)

        XCTAssertEqual(requests.map(\.httpMethod), ["GET", "PATCH", "GET", "GET", "PATCH", "POST"])

        let userPatch = requestBodies
            .compactMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Int] }
            .first { $0["forgiveness_tokens"] == 0 }
        XCTAssertNotNil(userPatch)

        let forgivenDailyLogSave = requestBodies
            .compactMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            .first { body in
                body["status"] as? String == "forgiven" &&
                    body["forgiveness_used"] as? Bool == true
            }
        XCTAssertNotNil(forgivenDailyLogSave)
    }

    private func makeChallengeEngine(calendar: Calendar = .current) -> ChallengeEngine {
        let supabase = makeSupabaseService()

        return ChallengeEngine(
            challengeService: ChallengeService(supabase: supabase),
            dailyLogService: DailyLogService(supabase: supabase),
            userService: UserService(supabase: supabase),
            calendar: calendar
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

    private static func jsonData(_ string: String) -> Data {
        Data(string.utf8)
    }

    private static func date(_ string: String) -> Date {
        ISO8601DateFormatter().date(from: string) ?? Date(timeIntervalSince1970: 0)
    }

    private static func gmtCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
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

    private static func challengeJSON(
        id: UUID,
        userId: UUID,
        currentDay: Int,
        status: String,
        startDate: String = "2026-03-10T00:00:00Z",
        endDate: String = "2026-06-08T00:00:00Z"
    ) -> String {
        """
        {
          "id": "\(id.uuidString)",
          "user_id": "\(userId.uuidString)",
          "start_date": "\(startDate)",
          "end_date": "\(endDate)",
          "current_day": \(currentDay),
          "status": "\(status)",
          "created_at": null
        }
        """
    }

    private static func dailyLogJSON(
        id: UUID,
        userId: UUID,
        status: String,
        habitsCompleted: Int = 2,
        habitsRequired: Int = 2,
        workoutCompleted: Bool = true,
        readingCompleted: Bool = true,
        forgivenessUsed: Bool = false
    ) -> String {
        """
        {
          "id": "\(id.uuidString)",
          "user_id": "\(userId.uuidString)",
          "date": "2026-06-08T00:00:00Z",
          "habits_completed": \(habitsCompleted),
          "habits_required": \(habitsRequired),
          "workout_completed": \(workoutCompleted),
          "reading_completed": \(readingCompleted),
          "forgiveness_used": \(forgivenessUsed),
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
