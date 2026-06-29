import Foundation

final class ExportService {

    func exportJSON(profile: Profile, dailyLogs: [DailyLog]) throws -> Data {
        struct ExportPayload: Codable {
            let profile: Profile
            let dailyLogs: [DailyLog]
            let exportedAt: Date
        }
        var exportProfile = profile
        exportProfile.email = nil
        let payload = ExportPayload(profile: exportProfile, dailyLogs: dailyLogs, exportedAt: Date())
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    func exportCSV(dailyLogs: [DailyLog]) -> Data {
        var csv = "date,habits_completed,habits_required,workout_completed,reading_completed,xp_earned,status\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for log in dailyLogs.sorted(by: { $0.date < $1.date }) {
            csv += [
                formatter.string(from: log.date),
                "\(log.habits_completed)", "\(log.habits_required)",
                "\(log.workout_completed)", "\(log.reading_completed)",
                "\(log.xp_earned)", log.status.rawValue
            ].joined(separator: ",") + "\n"
        }
        return Data(csv.utf8)
    }

    func exportFileURL(data: Data, filename: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url)
        return url
    }
}
