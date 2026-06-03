import Foundation
import Supabase
import XCTest
@testable import RNF

@MainActor
final class ReadingEngineTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testCompleteReadingUploadsProofAndUpdatesDailyLog() async throws {
        let userId = UUID()
        let dailyLogId = UUID()
        let uploadId = UUID()
        let date = Self.date("2026-06-08T00:00:00Z")
        var requests: [URLRequest] = []
        var requestBodies: [Data] = []
        var dailyLogFetchCount = 0
        var didUploadProof = false
        var didInsertReadingUpload = false

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

            if request.httpMethod == "POST", url.contains("/storage/v1/object/reading-proof/") {
                didUploadProof = true
                return (
                    response,
                    Self.jsonData(
                        """
                        {
                          "Key": "reading-proof/\(userId.uuidString)/2026-06-08.jpg",
                          "Id": "storage-id"
                        }
                        """
                    )
                )
            }

            if request.httpMethod == "POST", url.contains("reading_uploads") {
                didInsertReadingUpload = true
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

            if request.httpMethod == "GET", url.contains("daily_logs") {
                dailyLogFetchCount += 1
                return (
                    response,
                    Self.jsonData(
                        Self.dailyLogJSON(
                            id: dailyLogId,
                            userId: userId,
                            readingCompleted: dailyLogFetchCount >= 3,
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
                            readingCompleted: true
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
        let engine = ReadingEngine(
            readingService: ReadingService(
                supabase: supabase,
                dailyLogService: dailyLogService
            ),
            dailyLogService: dailyLogService,
            xpService: XPService(),
            challengeEngine: ChallengeEngine(
                challengeService: ChallengeService(supabase: supabase),
                dailyLogService: dailyLogService
            )
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

        let result = await engine.completeReading(
            imageData: Data("proof-image".utf8),
            date: date
        )

        XCTAssertEqual(result?.upload.id, uploadId)
        XCTAssertEqual(
            result?.upload.image_url,
            "reading-proof/\(userId.uuidString)/2026-06-08.jpg"
        )
        XCTAssertEqual(result?.xpAwarded, 10)
        XCTAssertEqual(result?.profile.xp_total, 205)
        XCTAssertEqual(result?.profile.level, 2)
        XCTAssertEqual(result?.dailyLog.xp_earned, 10)
        XCTAssertEqual(gameState.profile.xp_total, 205)
        XCTAssertEqual(gameState.level, 2)
        XCTAssertEqual(gameState.dailyLog.reading_completed, true)

        XCTAssertTrue(didUploadProof)
        XCTAssertTrue(didInsertReadingUpload)

        let readingPatch = requestBodies
            .compactMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Bool] }
            .first { $0["reading_completed"] == true }
        XCTAssertNotNil(readingPatch)
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
        readingCompleted: Bool,
        wrappedInArray: Bool = false
    ) -> String {
        let object = """
        {
          "id": "\(id.uuidString)",
          "user_id": "\(userId.uuidString)",
          "date": "2026-06-08T00:00:00Z",
          "habits_completed": 2,
          "habits_required": 2,
          "workout_completed": true,
          "reading_completed": \(readingCompleted),
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
