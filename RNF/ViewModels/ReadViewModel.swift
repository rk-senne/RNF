import Foundation
import Combine

@MainActor
final class ReadViewModel: ObservableObject {

    @Published var persistenceError: RNFServiceError?

    private let readingService: ReadingService

    init(readingService: ReadingService = ReadingService()) {
        self.readingService = readingService
    }

    func completeReading(userId: UUID, imageData: Data, date: Date = Date()) async {
        let result = await readingService.completeReadingSafe(userId: userId, date: date)
        persistenceError = result.error
    }

    func dismissError() {
        persistenceError = nil
    }
}
