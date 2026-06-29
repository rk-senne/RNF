import SwiftUI

// P20-EXP-12c: Arc Archive — displays all 12 seasonal arcs with completion status
struct ArcArchiveView: View {
    private let currentMonth = Calendar.current.component(.month, from: Date())
    private let completedArcs = SeasonalArcService.completedArcs()

    var body: some View {
        List(SeasonalArc.all, id: \.month) { arc in
            HStack {
                VStack(alignment: .leading, spacing: RNFSpacing.xs) {
                    Text(arc.name)
                        .font(RNFFont.body)
                        .foregroundStyle(foregroundColor(for: arc))
                    Text(arc.title)
                        .font(RNFFont.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                statusIcon(for: arc)
            }
            .opacity(arc.month > currentMonth ? 0.4 : 1.0)
        }
        .navigationTitle("Arc Archive")
    }

    private func isCompleted(_ arc: SeasonalArc) -> Bool {
        completedArcs.contains { $0.contains(arc.name) }
    }

    private func foregroundColor(for arc: SeasonalArc) -> Color {
        if isCompleted(arc) { return .primary }
        if arc.month < currentMonth { return .secondary }
        return .primary
    }

    @ViewBuilder
    private func statusIcon(for arc: SeasonalArc) -> some View {
        if isCompleted(arc) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else if arc.month < currentMonth {
            Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
        } else {
            EmptyView()
        }
    }
}
