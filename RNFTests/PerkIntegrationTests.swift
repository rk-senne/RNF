import Foundation
import Supabase
import XCTest
@testable import RNF

@MainActor
final class PerkIntegrationTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testHabitCompletionAppliesXPAndStatPerksThroughProgressionEngine() async throws {
        let userId = UUID()
        let habitId = UUID()
        let dailyLogId = UUID()
        let xpNodeId = UUID()
        let statNodeId = UUID()
        var requestBodies: [Data] = []

        MockURLProtocol.requestHandler = { request in
            if let body = Self.requestBodyData(from: request) {
                requestBodies.append(body)
            }

            let response = Self.response(for: request)
            let url = request.url?.absoluteString ?? ""

            if request.httpMethod == "GET", url.contains("daily_logs") {
                return (
                    response,
                    Self.jsonData(
                        "[\(Self.dailyLogJSON(id: dailyLogId, userId: userId, xpEarned: 80, status: "partial"))]"
                    )
                )
            }

            if request.httpMethod == "GET", url.contains("skill_nodes") {
                return (
                    response,
                    Self.jsonData(
                        """
                        [
                          \(Self.skillNodeJSON(id: xpNodeId, name: "XP Surge", statType: "energy", perkType: "xp_multiplier", perkValue: 50)),
                          \(Self.skillNodeJSON(id: statNodeId, name: "Focused Mind", statType: "energy", perkType: "stat_bonus", perkValue: 2))
                        ]
                        """
                    )
                )
            }

            if request.httpMethod == "GET", url.contains("user_skills") {
                return (
                    response,
                    Self.jsonData(
                        """
                        [
                          \(Self.userSkillJSON(userId: userId, nodeId: xpNodeId)),
                          \(Self.userSkillJSON(userId: userId, nodeId: statNodeId))
                        ]
                        """
                    )
                )
            }

            if request.httpMethod == "GET", url.contains("habit_completions") {
                return (response, Self.jsonData("[]"))
            }

            if request.httpMethod == "POST", url.contains("habit_completions") {
                let completion = Self.habitCompletionJSON(from: request, fallbackUserId: userId, fallbackHabitId: habitId)
                return (response, Self.jsonData(completion))
            }

            if request.httpMethod == "PATCH", url.contains("daily_logs") {
                return (
                    response,
                    Self.jsonData(
                        Self.dailyLogJSON(id: dailyLogId, userId: userId, xpEarned: 95, status: "complete")
                    )
                )
            }

            return (response, Self.jsonData("{}"))
        }

        let supabase = makeSupabaseService()
        let dailyLogService = DailyLogService(
            supabase: supabase,
            userService: UserService(supabase: supabase)
        )
        let engine = ProgressionEngine(
            dailyLogService: dailyLogService,
            xpService: XPService(),
            questService: QuestService(supabase: supabase),
            skillTreeService: SkillTreeService(supabase: supabase)
        )
        let gameState = GameState()
        var profile = Self.makeProfile(id: userId)
        profile.xp_total = 10
        profile.energy = 10
        let habit = Habit(id: habitId, name: "Drink Water", description: "Hydrate", xpReward: 10)

        gameState.apply(
            profile: profile,
            levelState: XPSystem.levelState(for: profile.xp_total),
            titles: [],
            quests: [habit],
            dailyGoal: 1,
            dailyCompleted: 0,
            completedHabitIDs: [],
            dailyLog: .today(goal: 1)
        )
        engine.configure(gameState: gameState)

        let progressionResult = await engine.processHabitCompletion(habitId: habitId)
        let result = try XCTUnwrap(progressionResult)

        XCTAssertEqual(result.xpGained, 15)
        XCTAssertEqual(result.updatedProfile.xp_total, 25)
        XCTAssertEqual(result.updatedProfile.energy, 13)
        XCTAssertEqual(result.updatedDailyLog.xp_earned, 95)
        XCTAssertTrue(result.missionCompleted)

        let completionBody = requestBodies
            .compactMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            .first { $0["xp_awarded"] as? Int == 15 }
        XCTAssertNotNil(completionBody)
    }

    func testQuestMapperAppliesQuestRewardPerksAtQuestBoundary() {
        let quest = Quest(
            id: UUID(),
            title: "Focus Sprint",
            description: "Complete a focused session",
            stat_strength: nil,
            stat_discipline: nil,
            stat_focus: 1,
            stat_energy: nil,
            stat_wisdom: nil,
            stat_mind: nil,
            stat_spirit: nil,
            xp_reward: 15,
            difficulty: .medium,
            cadence: .daily,
            category: "focus"
        )
        let activePerks = ActivePerkSummary(
            effects: [],
            unlockedSkillNodeIDs: [],
            xpMultiplierPercent: 0,
            statBonuses: [:],
            questRewardBonus: 5,
            streakProtectionCount: 0
        )

        let habit = QuestMapper.toHabit(quest, activePerks: activePerks)

        XCTAssertEqual(habit.id, quest.id)
        XCTAssertEqual(habit.xpReward, 20)
    }

    func testWorkoutAndReadingEnginesApplyXPPerksThroughSkillTreeService() async throws {
        let userId = UUID()
        let workoutLogId = UUID()
        let readingLogId = UUID()
        let uploadId = UUID()
        let xpNodeId = UUID()
        let date = Self.date("2026-06-08T00:00:00Z")
        var dailyLogFetchCount = 0

        MockURLProtocol.requestHandler = { request in
            let response = Self.response(for: request)
            let url = request.url?.absoluteString ?? ""

            if request.httpMethod == "GET", url.contains("skill_nodes") {
                return (
                    response,
                    Self.jsonData("[\(Self.skillNodeJSON(id: xpNodeId, name: "XP Surge", statType: "energy", perkType: "xp_multiplier", perkValue: 50))]")
                )
            }

            if request.httpMethod == "GET", url.contains("user_skills") {
                return (
                    response,
                    Self.jsonData("[\(Self.userSkillJSON(userId: userId, nodeId: xpNodeId))]")
                )
            }

            if request.httpMethod == "GET", url.contains("daily_logs") {
                dailyLogFetchCount += 1
                let isReadingPath = dailyLogFetchCount > 3
                return (
                    response,
                    Self.jsonData(
                        "[\(Self.dailyLogJSON(id: isReadingPath ? readingLogId : workoutLogId, userId: userId, xpEarned: 0, workoutCompleted: dailyLogFetchCount >= 3, readingCompleted: dailyLogFetchCount >= 6, status: "complete"))]"
                    )
                )
            }

            if request.httpMethod == "PATCH", url.contains("daily_logs") {
                let isReadingPatch = dailyLogFetchCount > 3
                return (
                    response,
                    Self.jsonData(
                        Self.dailyLogJSON(id: isReadingPatch ? readingLogId : workoutLogId, userId: userId, xpEarned: 0, workoutCompleted: true, readingCompleted: isReadingPatch, status: "complete")
                    )
                )
            }

            if request.httpMethod == "POST", url.contains("/storage/v1/object/reading-proof/") {
                return (response, Self.jsonData(#"{"Key":"reading-proof/test.jpg","Id":"storage-id"}"#))
            }

            if request.httpMethod == "POST", url.contains("reading_uploads") {
                return (
                    response,
                    Self.jsonData(
                        Self.readingUploadJSON(
                            id: uploadId,
                            userId: userId,
                            imageURL: "reading-proof/\(userId.uuidString)/2026-06-08.jpg"
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
        let dailyLogService = DailyLogService(
            supabase: supabase,
            userService: UserService(supabase: supabase)
        )
        let challengeEngine = ChallengeEngine(
            challengeService: ChallengeService(supabase: supabase),
            dailyLogService: dailyLogService,
            skillTreeService: SkillTreeService(supabase: supabase)
        )
        let workoutEngine = WorkoutEngine(
            workoutService: WorkoutService(
                supabase: supabase,
                dailyLogService: dailyLogService
            ),
            dailyLogService: dailyLogService,
            challengeEngine: challengeEngine,
            skillTreeService: SkillTreeService(supabase: supabase)
        )
        let readingEngine = ReadingEngine(
            readingService: ReadingService(
                supabase: supabase,
                dailyLogService: dailyLogService
            ),
            dailyLogService: dailyLogService,
            challengeEngine: challengeEngine,
            skillTreeService: SkillTreeService(supabase: supabase)
        )
        let gameState = GameState()
        gameState.profile = Self.makeProfile(id: userId)
        workoutEngine.configure(gameState: gameState)
        readingEngine.configure(gameState: gameState)

        let completedWorkout = await workoutEngine.completeWorkout(
            durationSeconds: 100,
            elapsedSeconds: 80,
            date: date
        )
        let workoutResult = try XCTUnwrap(completedWorkout)
        let completedReading = await readingEngine.completeReading(
            imageData: Data("proof".utf8),
            date: date
        )
        let readingResult = try XCTUnwrap(completedReading)

        XCTAssertEqual(workoutResult.xpAwarded, 22)
        XCTAssertEqual(workoutResult.profile.xp_total, 22)
        XCTAssertEqual(readingResult.xpAwarded, 15)
        XCTAssertEqual(readingResult.profile.xp_total, 37)
    }

    func testChallengeForgivenessUsesStreakProtectionPerkWithoutStoredToken() async throws {
        let userId = UUID()
        let dailyLogId = UUID()
        let streakNodeId = UUID()
        let date = Self.date("2026-06-08T00:00:00Z")
        var requests: [URLRequest] = []

        MockURLProtocol.requestHandler = { request in
            requests.append(request)

            let response = Self.response(for: request)
            let url = request.url?.absoluteString ?? ""

            if request.httpMethod == "GET", url.contains("daily_logs") {
                return (
                    response,
                    Self.jsonData(
                        "[\(Self.dailyLogJSON(id: dailyLogId, userId: userId, xpEarned: 0, workoutCompleted: false, readingCompleted: false, status: "missed"))]"
                    )
                )
            }

            if request.httpMethod == "PATCH", url.contains("daily_logs") {
                return (
                    response,
                    Self.jsonData(
                        Self.dailyLogJSON(id: dailyLogId, userId: userId, xpEarned: 0, workoutCompleted: false, readingCompleted: false, status: "missed")
                    )
                )
            }

            if request.httpMethod == "GET", url.contains("users") {
                return (response, Self.jsonData(#"[{"forgiveness_tokens":0}]"#))
            }

            if request.httpMethod == "GET", url.contains("skill_nodes") {
                return (
                    response,
                    Self.jsonData("[\(Self.skillNodeJSON(id: streakNodeId, name: "Shielded Streak", statType: "spirit", perkType: "streak_protection", perkValue: 1))]")
                )
            }

            if request.httpMethod == "GET", url.contains("user_skills") {
                return (
                    response,
                    Self.jsonData("[\(Self.userSkillJSON(userId: userId, nodeId: streakNodeId))]")
                )
            }

            return (response, Self.jsonData("{}"))
        }

        let supabase = makeSupabaseService()
        let dailyLogService = DailyLogService(supabase: supabase)
        let engine = ChallengeEngine(
            challengeService: ChallengeService(supabase: supabase),
            dailyLogService: dailyLogService,
            userService: UserService(supabase: supabase),
            skillTreeService: SkillTreeService(supabase: supabase)
        )

        let forgivenessResult = await engine.useForgiveness(
            userId: userId,
            date: date,
            currentStreak: 9
        )
        let result = try XCTUnwrap(forgivenessResult)

        XCTAssertEqual(result.dailyLog.status, .forgiven)
        XCTAssertEqual(result.remainingTokens, 0)
        XCTAssertEqual(result.preservedStreak, 9)
        XCTAssertFalse(requests.contains { $0.httpMethod == "PATCH" && ($0.url?.absoluteString.contains("users") ?? false) })
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

    private static func response(for request: URLRequest) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
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

    private static func skillNodeJSON(
        id: UUID,
        name: String,
        statType: String,
        perkType: String,
        perkValue: Int
    ) -> String {
        """
        {
          "id": "\(id.uuidString)",
          "name": "\(name)",
          "stat_type": "\(statType)",
          "tier": 1,
          "required_stat": null,
          "required_node": null,
          "perk_type": "\(perkType)",
          "perk_value": \(perkValue)
        }
        """
    }

    private static func userSkillJSON(userId: UUID, nodeId: UUID) -> String {
        """
        {
          "id": "\(UUID().uuidString)",
          "user_id": "\(userId.uuidString)",
          "skill_node_id": "\(nodeId.uuidString)",
          "unlocked_at": "2026-06-01T00:00:00Z"
        }
        """
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

    private static func readingUploadJSON(id: UUID, userId: UUID, imageURL: String) -> String {
        """
        {
          "id": "\(id.uuidString)",
          "user_id": "\(userId.uuidString)",
          "image_url": "\(imageURL)",
          "date": "2026-06-08T00:00:00Z",
          "created_at": null
        }
        """
    }

    private static func dailyLogJSON(
        id: UUID,
        userId: UUID,
        xpEarned: Int,
        workoutCompleted: Bool = true,
        readingCompleted: Bool = true,
        status: String
    ) -> String {
        """
        {
          "id": "\(id.uuidString)",
          "user_id": "\(userId.uuidString)",
          "date": "2026-06-08T00:00:00Z",
          "habits_completed": 1,
          "habits_required": 1,
          "workout_completed": \(workoutCompleted),
          "reading_completed": \(readingCompleted),
          "forgiveness_used": false,
          "xp_earned": \(xpEarned),
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
