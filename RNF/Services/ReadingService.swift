import Foundation
import Supabase
import PostgREST

final class ReadingService {

    private static let proofBucket = "reading-proof"
    private static let proofContentType = "image/jpeg"

    private let supabase: SupabaseService
    private let dailyLogService: DailyLogService

    init(
        supabase: SupabaseService = .shared,
        dailyLogService: DailyLogService = DailyLogService()
    ) {
        self.supabase = supabase
        self.dailyLogService = dailyLogService
    }

    func uploadReadingProof(
        imageData: Data,
        userId: UUID,
        date: Date = Date()
    ) async throws -> ReadingUpload {

        let path = Self.proofPath(userId: userId, date: date)

        try await supabase.client.storage
            .from(Self.proofBucket)
            .upload(
                path,
                data: imageData,
                options: FileOptions(contentType: Self.proofContentType)
            )

        let upload = ReadingUpload(
            id: UUID(),
            user_id: userId,
            image_url: "\(Self.proofBucket)/\(path)",
            date: date.startOfDay,
            created_at: nil
        )

        let createdUpload: ReadingUpload = try await supabase.client
            .from("reading_uploads")
            .insert(upload)
            .select()
            .single()
            .execute()
            .value

        _ = try await completeReading(userId: userId, date: date)

        return createdUpload
    }

    func dailyLogForReading(userId: UUID, date: Date = Date()) async throws -> DailyLog {
        if let dailyLog = try await dailyLogService.fetchTodayLog(userId: userId, date: date) {
            return dailyLog
        }

        return try await dailyLogService.createDailyLog(userId: userId, date: date)
    }

    func completeReading(userId: UUID, date: Date = Date()) async throws -> DailyLog {
        let dailyLog = try await dailyLogForReading(userId: userId, date: date)

        struct ReadingCompletionUpdate: Encodable {
            let reading_completed: Bool
        }

        let completedLog: DailyLog = try await supabase.client
            .from("daily_logs")
            .update(ReadingCompletionUpdate(reading_completed: true))
            .eq("id", value: dailyLog.id.uuidString)
            .select()
            .single()
            .execute()
            .value

        return try await dailyLogService.updateStatus(userId: userId, date: date) ?? completedLog
    }

    private static func proofPath(userId: UUID, date: Date) -> String {
        "\(userId.uuidString)/\(date.formatted("yyyy-MM-dd")).jpg"
    }

}
