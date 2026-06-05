import Foundation
import Supabase
import PostgREST

final class ReadingService {

    private static let proofBucket = "reading-proof"
    private static let proofContentType = "image/jpeg"

    private let supabase: SupabaseService
    private let dailyLogService: DailyLogService
    private let authProvider: AuthProviding
    private let calendar: Calendar

    init(
        supabase: SupabaseService = .shared,
        dailyLogService: DailyLogService? = nil,
        authProvider: AuthProviding? = nil,
        calendar: Calendar = .current
    ) {
        self.supabase = supabase
        self.dailyLogService = dailyLogService ?? DailyLogService(
            supabase: supabase,
            calendar: calendar
        )
        self.authProvider = authProvider ?? AuthService(supabase: supabase)
        self.calendar = calendar
    }

    func uploadReadingProof(
        imageData: Data,
        userId: UUID,
        date: Date = Date()
    ) async throws -> ReadingUpload {

        if let existingUpload = try await fetchReadingUpload(userId: userId, date: date) {
            _ = try await completeReading(userId: userId, date: date)
            return existingUpload
        }

        let normalizedDate = DayBoundaryPolicy.normalizedDay(
            for: date,
            calendar: calendar
        )
        let path = Self.proofPath(userId: userId, date: date, calendar: calendar)

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
            date: normalizedDate,
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

    func uploadReadingProof(
        imageData: Data,
        date: Date = Date()
    ) async throws -> ReadingUpload {

        let userId = try await authProvider.requireCurrentUserID()
        return try await uploadReadingProof(
            imageData: imageData,
            userId: userId,
            date: date
        )
    }

    func dailyLogForReading(userId: UUID, date: Date = Date()) async throws -> DailyLog {
        if let dailyLog = try await dailyLogService.fetchTodayLog(userId: userId, date: date) {
            return dailyLog
        }

        return try await dailyLogService.createDailyLog(userId: userId, date: date)
    }

    func dailyLogForReading(date: Date = Date()) async throws -> DailyLog {
        let userId = try await authProvider.requireCurrentUserID()
        return try await dailyLogForReading(userId: userId, date: date)
    }

    func completeReading(userId: UUID, date: Date = Date()) async throws -> DailyLog {
        let dailyLog = try await dailyLogForReading(userId: userId, date: date)

        guard !dailyLog.reading_completed else {
            return dailyLog
        }

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

    func completeReading(date: Date = Date()) async throws -> DailyLog {
        let userId = try await authProvider.requireCurrentUserID()
        return try await completeReading(userId: userId, date: date)
    }

    private static func proofPath(
        userId: UUID,
        date: Date,
        calendar: Calendar
    ) -> String {
        "\(userId.uuidString)/\(DayBoundaryPolicy.dayIdentifier(for: date, calendar: calendar)).jpg"
    }

    private func fetchReadingUpload(userId: UUID, date: Date) async throws -> ReadingUpload? {

        let uploads: [ReadingUpload] = try await supabase.client
            .from("reading_uploads")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: DayBoundaryPolicy.normalizedDay(for: date, calendar: calendar))
            .limit(1)
            .execute()
            .value

        return uploads.first
    }

}
