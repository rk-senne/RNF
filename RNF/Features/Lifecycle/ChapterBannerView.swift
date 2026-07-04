import SwiftUI

// P27-LIF-04: Chapter Banner View
// Replaces challenge day counter after Day 90 with chapter objective display.
// Shows current chapter title, objective, and progress toward next milestone.

struct ChapterBannerView: View {

    @ObservedObject var chapterService: ChapterService

    var body: some View {
        VStack(alignment: .leading, spacing: RNFSpacing.sm) {
            // Chapter title
            HStack {
                Image(systemName: "book.pages.fill")
                    .foregroundStyle(.secondary)

                Text(chapterService.currentChapter.title)
                    .font(RNFFont.headline)
                    .foregroundStyle(.primary)

                Spacer()

                if chapterService.currentProgress >= 1.0 {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }

            // Current objective
            Text(chapterService.currentObjective)
                .font(RNFFont.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Progress bar
            ProgressView(value: chapterService.currentProgress)
                .tint(progressTint)
                .animation(.easeInOut(duration: 0.3), value: chapterService.currentProgress)

            // Progress percentage
            HStack {
                Text("\(Int(chapterService.currentProgress * 100))%")
                    .font(RNFFont.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(chapterService.currentChapter.subtitle)
                    .font(RNFFont.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(RNFSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: RNFRadius.md)
                .fill(.ultraThinMaterial)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chapter progress: \(chapterService.currentChapter.title), \(Int(chapterService.currentProgress * 100)) percent complete")
    }

    // MARK: - Private

    private var progressTint: Color {
        switch chapterService.currentChapter {
        case .origin: return .blue
        case .newPillar: return .purple
        case .balanced: return .green
        case .specialist: return .orange
        case .complete: return .yellow
        }
    }
}

#Preview {
    ChapterBannerView(chapterService: ChapterService())
        .padding()
}
