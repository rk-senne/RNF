import UIKit
import XCTest
@testable import RNF

@MainActor
final class ReadViewModelTests: XCTestCase {

    func testLoadSelectedImageDataStoresPreviewAndMarksProofReady() {
        let viewModel = ReadViewModel(readingCompleter: StubReadingCompleter())

        viewModel.loadSelectedImageData(Self.imageData())

        XCTAssertNotNil(viewModel.selectedImageData)
        XCTAssertNotNil(viewModel.selectedImage)
        XCTAssertEqual(viewModel.uploadState, .ready)
    }

    func testSubmitProofFailsWhenPhotoIsMissing() async {
        let viewModel = ReadViewModel(readingCompleter: StubReadingCompleter())

        await viewModel.submitProof()

        XCTAssertEqual(viewModel.uploadState, .failed("Choose a photo first"))
    }

    func testSubmitProofCompletesThroughReadingCompleter() async {
        let completer = StubReadingCompleter(result: Self.completionResult(xpAwarded: 14))
        let viewModel = ReadViewModel(readingCompleter: completer)
        viewModel.loadSelectedImageData(Self.imageData())

        await viewModel.submitProof()

        XCTAssertEqual(completer.completedImageData, viewModel.selectedImageData)
        XCTAssertEqual(viewModel.uploadState, .completed(14))
    }

    func testSubmitProofAppliesCompletionResultToConfiguredGameState() async {
        let completer = StubReadingCompleter(result: Self.completionResult(xpAwarded: 14))
        let viewModel = ReadViewModel(readingCompleter: completer)
        let gameState = GameState()
        viewModel.configure(gameState: gameState)
        viewModel.loadSelectedImageData(Self.imageData())

        await viewModel.submitProof()

        XCTAssertEqual(gameState.profile.xp_total, 14)
        XCTAssertEqual(gameState.level, 1)
        XCTAssertEqual(gameState.xp, 14)
        XCTAssertTrue(gameState.dailyLog.reading_completed)
    }

    func testSubmitProofSurfacesUploadFailure() async {
        let viewModel = ReadViewModel(readingCompleter: StubReadingCompleter(result: nil))
        viewModel.loadSelectedImageData(Self.imageData())

        await viewModel.submitProof()

        XCTAssertEqual(viewModel.uploadState, .failed("Proof could not be uploaded"))
    }

    private static func imageData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8))
        let image = renderer.image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }

        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }

    private static func completionResult(xpAwarded: Int) -> ReadingCompletionResult {
        let userId = UUID()
        let date = Date(timeIntervalSince1970: 0)
        let profile = Profile(
            id: userId,
            email: "reader@example.com",
            xp_total: xpAwarded,
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

        var dailyLog = DailyLog.today(userID: userId, goal: 3)
        dailyLog.reading_completed = true
        dailyLog.xp_earned = xpAwarded

        return ReadingCompletionResult(
            upload: ReadingUpload(
                id: UUID(),
                user_id: userId,
                image_url: "reading-proof/\(userId.uuidString)/1970-01-01.jpg",
                date: date
            ),
            dailyLog: dailyLog,
            profile: profile,
            xpAwarded: xpAwarded,
            levelState: XPSystem.levelState(for: xpAwarded),
            advancedChallenge: nil
        )
    }

}

private final class StubReadingCompleter: ReadingCompleting {

    private let result: ReadingCompletionResult?
    private(set) var completedImageData: Data?
    private(set) var configuredGameState: GameState?

    init(result: ReadingCompletionResult? = nil) {
        self.result = result
    }

    func configure(gameState: GameState) {
        configuredGameState = gameState
    }

    func completeReading(
        imageData: Data,
        date: Date
    ) async -> ReadingCompletionResult? {
        completedImageData = imageData
        return result
    }

}
