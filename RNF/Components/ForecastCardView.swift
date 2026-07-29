import SwiftUI

/// Displays progress forecast with projected level date and pace indicator.
/// Shows current pace, risk level, and days to next streak tier.
struct ForecastCardView: View {

    let projection: ProgressForecast.Projection

    private var paceDescription: String {
        String(format: "%.1f habits/day", projection.currentPace)
    }

    private var trendArrow: String {
        if projection.paceTrend > 0.3 { return "↑" }
        if projection.paceTrend < -0.3 { return "↓" }
        return "→"
    }

    private var trendColor: Color {
        if projection.paceTrend > 0.3 { return .green }
        if projection.paceTrend < -0.3 { return .orange }
        return .secondary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: RNFSpacing.sm) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color.accentColor)
                Text("Forge Forecast")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(projection.riskLevel.emoji)
            }

            // Pace row
            HStack {
                Text("Pace")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(paceDescription) \(trendArrow)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(trendColor)
            }

            // Next level projection
            if let nextDate = projection.projectedNextLevelDate {
                HStack {
                    Text("Next Level")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(nextDate, style: .date)
                        .font(.caption.weight(.medium))
                }
            }

            // Streak tier projection
            if let daysToNext = projection.daysToNextTier {
                HStack {
                    Text("Next Streak Tier")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(daysToNext) days")
                        .font(.caption.weight(.medium))
                }
            }

            // Risk message
            if projection.riskLevel != .onTrack {
                Text(riskMessage)
                    .font(.caption2)
                    .foregroundStyle(projection.riskLevel == .atRisk ? .red : .orange)
                    .padding(.top, 2)
            }
        }
        .padding(RNFSpacing.md)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: RNFRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progress forecast: \(paceDescription), \(projection.riskLevel.rawValue)")
    }

    private var riskMessage: String {
        switch projection.riskLevel {
        case .onTrack:
            return ""
        case .slipping:
            return "Your pace dropped this week. One more habit tomorrow keeps you on track."
        case .atRisk:
            return "Less than 1 habit/day puts your streak at risk. Even a single completion helps."
        }
    }
}
