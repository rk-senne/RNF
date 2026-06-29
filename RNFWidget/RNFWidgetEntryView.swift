import SwiftUI
import WidgetKit

struct RNFWidgetEntryView: View {
    let entry: RNFWidgetEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

struct SmallWidgetView: View {
    let data: RNFWidgetData

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(data.streakCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }

            Text("day streak")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            ProgressRing(progress: data.dailyProgress)
                .frame(width: 44, height: 44)
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    let data: RNFWidgetData

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(data.streakCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                ProgressRing(progress: data.dailyProgress)
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(zip(data.questNames.indices, data.questNames)), id: \.0) { index, name in
                    HStack(spacing: 6) {
                        Image(systemName: (index < data.questCompletions.count && data.questCompletions[index])
                              ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundStyle(
                                (index < data.questCompletions.count && data.questCompletions[index])
                                ? .green : .secondary
                            )
                        Text(name)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
    }
}

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.purple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
    }
}
