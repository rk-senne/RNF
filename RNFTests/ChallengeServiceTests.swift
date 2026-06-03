import Foundation
import Supabase
import XCTest
@testable import RNF

final class ChallengeServiceTests: XCTestCase {

    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        super.tearDown()
    }

    func testAdvanceDayPersistsNextChallengeDay() async throws {
        let userId = UUID()
        let challengeId = UUID()
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

            return (
                response,
                Self.jsonData(
                    Self.challengeJSON(
                        id: challengeId,
                        userId: userId,
                        currentDay: 2,
                        status: "active"
                    )
                )
            )
        }

        let service = ChallengeService(supabase: makeSupabaseService())
        let result = try await service.advanceDay(
            Challenge(
                id: challengeId,
                user_id: userId,
                start_date: Date(timeIntervalSince1970: 1_772_582_400),
                end_date: Date(timeIntervalSince1970: 1_780_272_000),
                current_day: 1,
                status: .active,
                created_at: nil
            )
        )

        XCTAssertEqual(result.id, challengeId)
        XCTAssertEqual(result.current_day, 2)
        XCTAssertEqual(requests.map(\.httpMethod), ["PATCH"])
        XCTAssertTrue(requests[0].url?.absoluteString.contains("challenges") ?? false)
        XCTAssertTrue(requests[0].url?.absoluteString.contains("id=eq.\(challengeId.uuidString)") ?? false)

        let body = try XCTUnwrap(patchBodies.first)
        let bodyObject = try JSONSerialization.jsonObject(with: body) as? [String: Int]
        XCTAssertEqual(bodyObject?["current_day"], 2)
    }

    func testAdvanceDayCapsAtFinalChallengeDay() async throws {
        let userId = UUID()
        let challengeId = UUID()
        var patchBodies: [Data] = []

        MockURLProtocol.requestHandler = { request in
            if let body = Self.requestBodyData(from: request) {
                patchBodies.append(body)
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            return (
                response,
                Self.jsonData(
                    Self.challengeJSON(
                        id: challengeId,
                        userId: userId,
                        currentDay: Challenge.totalDays,
                        status: "active"
                    )
                )
            )
        }

        let service = ChallengeService(supabase: makeSupabaseService())
        let result = try await service.advanceDay(
            Challenge(
                id: challengeId,
                user_id: userId,
                start_date: Date(timeIntervalSince1970: 1_772_582_400),
                end_date: Date(timeIntervalSince1970: 1_780_272_000),
                current_day: Challenge.totalDays,
                status: .active,
                created_at: nil
            )
        )

        XCTAssertEqual(result.current_day, Challenge.totalDays)

        let body = try XCTUnwrap(patchBodies.first)
        let bodyObject = try JSONSerialization.jsonObject(with: body) as? [String: Int]
        XCTAssertEqual(bodyObject?["current_day"], Challenge.totalDays)
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
