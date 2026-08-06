import Foundation
import XCTest
import Supabase
@testable import RNF

@MainActor
final class ViewModelFailureStateTests: XCTestCase {

    func testWorkoutViewModelSurfacesPersistenceError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let supabase = makeSupabaseService()
        let service = WorkoutService(
            supabase: supabase,
            dailyLogService: DailyLogService(supabase: supabase),
            authProvider: MockAuthProvider(userID: UUID())
        )
        let viewModel = WorkoutViewModel(workoutService: service)

        await viewModel.completeWorkout(userId: UUID(), durationSeconds: 100, elapsedSeconds: 80)

        XCTAssertNotNil(viewModel.persistenceError)
        XCTAssertEqual(viewModel.persistenceError, .unknown)
    }

    func testWorkoutViewModelClearsPersistenceErrorOnDismiss() async {
        let viewModel = WorkoutViewModel()
        viewModel.persistenceError = .unknown

        viewModel.dismissError()

        XCTAssertNil(viewModel.persistenceError)
    }

    func testReadViewModelSurfacesPersistenceError() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        let supabase = makeSupabaseService()
        let service = ReadingService(
            supabase: supabase,
            dailyLogService: DailyLogService(supabase: supabase),
            authProvider: MockAuthProvider(userID: UUID())
        )
        let viewModel = ReadViewModel(readingService: service)

        await viewModel.completeReading(userId: UUID(), imageData: Data())

        XCTAssertNotNil(viewModel.persistenceError)
        XCTAssertEqual(viewModel.persistenceError, .unknown)
    }

    func testReadViewModelClearsPersistenceErrorOnDismiss() async {
        let viewModel = ReadViewModel()
        viewModel.persistenceError = .unknown

        viewModel.dismissError()

        XCTAssertNil(viewModel.persistenceError)
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
