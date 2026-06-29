import Foundation
import Supabase
import PostgREST
import os

final class ReadingService {

    private static let proofBucket = "reading-proof"
    private static let proofContentType = "image/jpeg"

    private let supabase: SupabaseService
    private let dailyLogService: DailyLogService
    private let authProvider: AuthProviding

    init(
        supabase: SupabaseService = .shared,
        dailyLogService: DailyLogService = DailyLogService(),
        authProvider: AuthProviding? = nil
    ) {
        self.supabase = supabase
        self.dailyLogService = dailyLogService
        self.authProvider = authProvider ?? AuthService(supabase: supabase)
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
            RNFLogger.sync.info("Reading already completed for today, skipping")
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

    func completeReadingSafe(userId: UUID, date: Date = Date()) async -> RNFServiceWriteResult<DailyLog> {
        do {
            let dailyLog = try await dailyLogForReading(userId: userId, date: date)

            guard !dailyLog.reading_completed else {
                return .savedRemotely(dailyLog)
            }

            let completedLog = try await completeReading(userId: userId, date: date)
            return .savedRemotely(completedLog)
        } catch {
            return .notSaved(.unknown)
        }
    }

    func completeReadingSafe(date: Date = Date()) async -> RNFServiceWriteResult<DailyLog> {
        do {
            let userId = try await authProvider.requireCurrentUserID()
            return await completeReadingSafe(userId: userId, date: date)
        } catch {
            return .notSaved(.unauthenticated)
        }
    }

    private static func proofPath(userId: UUID, date: Date) -> String {
        "\(userId.uuidString)/\(date.formatted("yyyy-MM-dd")).jpg"
    }

}
