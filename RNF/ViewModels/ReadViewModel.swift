import Foundation
import Combine
import PhotosUI
import SwiftUI
import UIKit

@MainActor
protocol ReadingCompleting: AnyObject {
    func configure(gameState: GameState)
    func completeReading(
        imageData: Data,
        date: Date
    ) async -> ReadingCompletionResult?
}

extension ReadingEngine: ReadingCompleting {
}

@MainActor
final class ReadViewModel: ObservableObject {

    enum UploadState: Equatable {
        case idle
        case loadingPhoto
        case ready
        case uploading
        case completed(Int)
        case failed(String)
    }

    @Published var selectedPhoto: PhotosPickerItem?
    @Published private(set) var selectedImageData: Data?
    @Published private(set) var selectedImage: UIImage?
    @Published private(set) var uploadState: UploadState = .idle

    private let readingCompleter: ReadingCompleting
    private weak var gameState: GameState?

    init() {
        self.readingCompleter = ReadingEngine()
    }

    init(readingCompleter: ReadingCompleting) {
        self.readingCompleter = readingCompleter
    }

    var photoButtonTitle: String {
        selectedImage == nil ? "Choose Photo" : "Change"
    }

    var submitButtonTitle: String {
        isUploading ? "Uploading" : "Submit"
    }

    var submitButtonIcon: String {
        isUploading ? "hourglass" : "arrow.up.circle.fill"
    }

    var isLoadingPhoto: Bool {
        if case .loadingPhoto = uploadState {
            return true
        }

        return false
    }

    var isUploading: Bool {
        if case .uploading = uploadState {
            return true
        }

        return false
    }

    func configure(gameState: GameState) {
        self.gameState = gameState
        readingCompleter.configure(gameState: gameState)
    }

    func loadSelectedPhoto(_ photo: PhotosPickerItem?) async {
        guard let photo else {
            return
        }

        uploadState = .loadingPhoto

        do {
            let data = try await photo.loadTransferable(type: Data.self)
            loadSelectedImageData(data)
        } catch {
            failPhotoLoad()
        }
    }

    func loadSelectedImageData(_ data: Data?) {
        guard
            let data,
            let image = UIImage(data: data)
        else {
            failPhotoLoad()
            return
        }

        selectedImageData = data
        selectedImage = image
        uploadState = .ready
    }

    func submitProof(date: Date = Date()) async {
        guard let selectedImageData else {
            uploadState = .failed("Choose a photo first")
            return
        }

        uploadState = .uploading

        if let result = await readingCompleter.completeReading(
            imageData: selectedImageData,
            date: date
        ) {
            applyCompletionResult(result)
            uploadState = .completed(result.xpAwarded)
        } else {
            uploadState = .failed("Proof could not be uploaded")
        }
    }

    private func failPhotoLoad() {
        selectedImageData = nil
        selectedImage = nil
        uploadState = .failed("Photo could not be loaded")
    }

    private func applyCompletionResult(_ result: ReadingCompletionResult) {
        guard let gameState else {
            return
        }

        gameState.apply(
            profile: result.profile,
            levelState: result.levelState,
            titles: gameState.titles,
            quests: gameState.quests,
            dailyGoal: gameState.dailyGoal,
            dailyCompleted: gameState.dailyCompleted,
            completedHabitIDs: gameState.completedHabitIDs,
            dailyLog: result.dailyLog
        )
    }

}
