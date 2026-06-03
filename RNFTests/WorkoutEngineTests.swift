import Foundation
import Supabase
import XCTest
@testable import RNF

@MainActor
final class WorkoutEngineTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testWorkoutDurationValidationUsesEightyPercentThreshold() {
        XCTAssertFalse(
            WorkoutDurationValidator.isComplete(
                durationSeconds: 100,
                elapsedSeconds: 79
            )
        )
        XCTAssertTrue(
            WorkoutDurationValidator.isComplete(
                durationSeconds: 100,
                elapsedSeconds: 80
            )
        )
    }

    func testCompleteWorkoutAwardsXPAndUpdatesGameState() async throws {
        let userId = UUID()
        let dailyLogId = UUID()
        let date = Self.date("2026-06-08T00:00:00Z")
        var requests: [URLRequest] = []
        var patchBodies: [Data] = []
        var dailyLogFetchCount = 0

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

            if request.httpMethod == "GET", url.contains("daily_logs") {
                dailyLogFetchCount += 1
                return (
                    response,
                    Self.jsonData(
                        Self.dailyLogJSON(
                            id: dailyLogId,
                            userId: userId,
                            workoutCompleted: dailyLogFetchCount >= 3,
                            wrappedInArray: true
                        )
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
                            workoutCompleted: true
                        )
                    )
                )
            }

            if request.httpMethod == "GET", url.contains("challenges") {
                return (response, Self.jsonData("[]"))
            }

            return (response, Self.jsonData("{}"))
        }

        let supabase = makeSupabaseService()
        let dailyLogService = DailyLogService(supabase: supabase)
        let engine = WorkoutEngine(
            workoutService: WorkoutService(
                supabase: supabase,
                dailyLogService: dailyLogService
            ),
            dailyLogService: dailyLogService,
            xpService: XPService(),
            challengeEngine: ChallengeEngine(
                challengeService: ChallengeService(supabase: supabase),
                dailyLogService: dailyLogService
            ),
            skillTreeService: SkillTreeService(supabase: supabase)
        )
        let gameState = GameState()
        gameState.profile = Profile(
            id: userId,
            email: "test@example.com",
            xp_total: 195,
            level: 1,
            streak: 0,
            forgiveness_tokens: 0,
            morning_notification_time: nil,
            evening_notification_time: nil,
            strength: 1,
            discipline: 1,
            focus: 1,
            energy: 1,
            wisdom: 1,
            mind: 1,
            spirit: 1,
            created_at: nil
        )

        engine.configure(gameState: gameState)

        let result = await engine.completeWorkout(
            durationSeconds: 100,
            elapsedSeconds: 80,
            date: date
        )

        XCTAssertEqual(result?.xpAwarded, 15)
        XCTAssertEqual(result?.profile.xp_total, 210)
        XCTAssertEqual(result?.profile.level, 2)
        XCTAssertEqual(result?.levelState.leveledUp, true)
        XCTAssertEqual(result?.dailyLog.xp_earned, 15)
        XCTAssertEqual(gameState.profile.xp_total, 210)
        XCTAssertEqual(gameState.level, 2)
        XCTAssertEqual(gameState.dailyLog.workout_completed, true)

        XCTAssertTrue(requests.contains { $0.httpMethod == "PATCH" && ($0.url?.absoluteString.contains("daily_logs") ?? false) })
        let workoutPatch = patchBodies
            .compactMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Bool] }
            .first { $0["workout_completed"] == true }
        XCTAssertNotNil(workoutPatch)
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
        workoutCompleted: Bool,
        wrappedInArray: Bool = false
    ) -> String {
        let object = """
        {
          "id": "\(id.uuidString)",
          "user_id": "\(userId.uuidString)",
          "date": "2026-06-08T00:00:00Z",
          "habits_completed": 2,
          "habits_required": 2,
          "workout_completed": \(workoutCompleted),
          "reading_completed": true,
          "forgiveness_used": false,
          "xp_earned": 0,
          "status": "complete",
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
