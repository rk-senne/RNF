import Foundation
import Supabase
import XCTest
@testable import RNF

@MainActor
final class HabitsViewModelFailureStateTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testCompleteHabitSurfacesCriticalPersistenceFailureWithoutApplyingProgress() async throws {
        let userId = UUID()
        let habitId = UUID()
        let dailyLogId = UUID()
        let habit = Habit(
            id: habitId,
            name: "Drink Water",
            description: "Hydrate",
            xpReward: 10
        )
        var requests: [URLRequest] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)

            let url = request.url?.absoluteString ?? ""
            let statusCode = request.httpMethod == "POST" && url.contains("daily_logs")
                ? 500
                : 200
            let response = Self.response(for: request, statusCode: statusCode)

            if request.httpMethod == "GET", url.contains("daily_logs") {
                return (
                    response,
                    Self.jsonData(
                        "[\(Self.dailyLogJSON(id: dailyLogId, userId: userId, xpEarned: 0, status: "partial"))]"
                    )
                )
            }

            if request.httpMethod == "GET", url.contains("skill_nodes") {
                return (response, Self.jsonData("[]"))
            }

            if request.httpMethod == "GET", url.contains("habit_completions") {
                return (response, Self.jsonData("[]"))
            }

            if request.httpMethod == "POST", url.contains("habit_completions") {
                return (
                    response,
                    Self.jsonData(
                        Self.habitCompletionJSON(
                            from: request,
                            fallbackUserId: userId,
                            fallbackHabitId: habitId
                        )
                    )
                )
            }

            if request.httpMethod == "POST", url.contains("daily_logs") {
                return (response, Self.jsonData(#"{"message":"daily log save failed"}"#))
            }

            return (response, Self.jsonData("{}"))
        }

        let supabase = makeSupabaseService()
        let viewModel = HabitsViewModel(
            progressionEngine: ProgressionEngine(
                dailyLogService: DailyLogService(supabase: supabase),
                skillTreeService: SkillTreeService(supabase: supabase)
            )
        )
        let gameState = GameState()
        let profile = Self.makeProfile(id: userId)
        gameState.apply(
            profile: profile,
            levelState: XPSystem.levelState(for: profile.xp_total),
            titles: [],
            quests: [habit],
            dailyGoal: 1,
            dailyCompleted: 0,
            completedHabitIDs: [],
            dailyLog: .today(userID: userId, goal: 1)
        )
        await viewModel.loadForTesting(gameState: gameState)

        await viewModel.completeHabit(habit)

        XCTAssertEqual(viewModel.completionErrorMessage, "We couldn't save that completion. Please try again.")
        XCTAssertNil(viewModel.xpGained)
        XCTAssertEqual(gameState.profile.xp_total, profile.xp_total)
        XCTAssertEqual(gameState.dailyCompleted, 0)
        XCTAssertFalse(gameState.completedHabitIDs.contains(habitId))
        XCTAssertTrue(requests.contains { $0.httpMethod == "POST" && ($0.url?.absoluteString.contains("daily_logs") ?? false) })
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

    private static func makeProfile(id: UUID) -> Profile {
        Profile(
            id: id,
            email: "test@example.com",
            xp_total: 0,
            level: 1,
            streak: 0,
            forgiveness_tokens: 0,
            morning_notification_time: nil,
            evening_notification_time: nil,
            strength: 10,
            discipline: 10,
            focus: 10,
            energy: 10,
            wisdom: 10,
            mind: 10,
            spirit: 10,
            created_at: nil
        )
    }

    private static func habitCompletionJSON(
        from request: URLRequest,
        fallbackUserId: UUID,
        fallbackHabitId: UUID
    ) -> String {
        let body = requestBodyData(from: request)
        let object = body.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } ?? [:]
        let id = object["id"] as? String ?? UUID().uuidString
        let userId = object["user_id"] as? String ?? fallbackUserId.uuidString
        let habitId = object["habit_id"] as? String ?? fallbackHabitId.uuidString
        let completedAt = object["completed_at"] as? String ?? "2026-06-08T00:00:00Z"
        let date = object["date"] as? String ?? "2026-06-08T00:00:00Z"
        let xpAwarded = object["xp_awarded"] as? Int ?? 0

        return """
        {
          "id": "\(id)",
          "user_id": "\(userId)",
          "habit_id": "\(habitId)",
          "completed_at": "\(completedAt)",
          "date": "\(date)",
          "xp_awarded": \(xpAwarded),
          "created_at": null
        }
        """
    }

    private static func dailyLogJSON(
        id: UUID,
        userId: UUID,
        xpEarned: Int,
        status: String
    ) -> String {
        """
        {
          "id": "\(id.uuidString)",
          "user_id": "\(userId.uuidString)",
          "date": "2026-06-08T00:00:00Z",
          "habits_completed": 0,
          "habits_required": 1,
          "workout_completed": false,
          "reading_completed": false,
          "forgiveness_used": false,
          "xp_earned": \(xpEarned),
          "status": "\(status)",
          "created_at": null
        }
        """
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
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
    }

}
