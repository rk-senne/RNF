import SwiftUI
import PhotosUI
import UIKit

struct ReadView: View {

    private struct ReadingArticle: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let duration: String
    }

    private let curatedArticles = [
        ReadingArticle(
            title: "Discipline Beats Intensity",
            subtitle: "Build the rhythm before chasing the rush.",
            duration: "4 min"
        ),
        ReadingArticle(
            title: "How to Recover Focus",
            subtitle: "A short reset for attention after a fractured day.",
            duration: "6 min"
        ),
        ReadingArticle(
            title: "The Compounding Effect of Pages",
            subtitle: "Tiny reading sessions that become identity.",
            duration: "5 min"
        )
    ]

    @EnvironmentObject private var game: GameState
    @StateObject private var viewModel: ReadViewModel

    init() {
        _viewModel = StateObject(wrappedValue: ReadViewModel())
    }

    init(viewModel: ReadViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("READ")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(Color.secondary)

                    Text("Train attention. Feed the mind. Log the proof.")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)

                dailyReadingCard
                readingTargetCard
                articleList
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Read")
        .navigationBarTitleDisplayMode(.large)
        .task {
            viewModel.configure(gameState: game)
        }
        .onChange(of: viewModel.selectedPhoto) { _, newPhoto in
            Task {
                await viewModel.loadSelectedPhoto(newPhoto)
            }
        }

    }

    private var dailyReadingCard: some View {

        VStack(alignment: .leading, spacing: 14) {
            Text("Daily Reading")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color(red: 0.3, green: 0.43, blue: 0.86))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color(red: 0.3, green: 0.43, blue: 0.86).opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Read 10 Pages")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.primary)

                    Text("Log today by uploading a book photo.")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        readingPill("Daily", tint: Color(red: 0.3, green: 0.43, blue: 0.86))
                        readingPill("+10 XP", tint: Color(red: 0.12, green: 0.54, blue: 0.3))
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "camera.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.secondary)
                }

                if let selectedImage = viewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .clipped()
                }

                uploadControls
            }
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
            .padding(16)
            .cardBackground()
        }

    }

    private var uploadControls: some View {

        let photoButtonTitle = viewModel.photoButtonTitle
        let submitButtonTitle = viewModel.submitButtonTitle
        let submitButtonIcon = viewModel.submitButtonIcon

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                PhotosPicker(
                    selection: $viewModel.selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(photoButtonTitle, systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isUploading)

                Button {
                    Task {
                        await viewModel.submitProof()
                    }
                } label: {
                    Label(submitButtonTitle, systemImage: submitButtonIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.selectedImageData == nil || viewModel.isUploading || viewModel.isLoadingPhoto)
            }

            uploadStatus
        }

    }

    @ViewBuilder
    private var uploadStatus: some View {

        switch viewModel.uploadState {
        case .idle:
            EmptyView()
        case .loadingPhoto:
            Label("Loading photo", systemImage: "hourglass")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.secondary)
        case .ready:
            Label("Proof ready", systemImage: "checkmark.circle.fill")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.12, green: 0.54, blue: 0.3))
        case .uploading:
            Label("Uploading proof", systemImage: "arrow.up.circle.fill")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.secondary)
        case .completed(let xp):
            Label("Reading Complete +\(xp) XP", systemImage: "checkmark.seal.fill")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.12, green: 0.54, blue: 0.3))
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.red)
        }

    }

    private var readingTargetCard: some View {

        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Target")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)

            HStack(spacing: 12) {
                metricTile(title: "Pages", value: "10")
                metricTile(title: "Proof", value: "Photo")
            }
        }

    }

    private var articleList: some View {

        VStack(alignment: .leading, spacing: 12) {
            Text("Curated Articles")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)

            ForEach(curatedArticles) { article in
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(red: 0.73, green: 0.36, blue: 0.18))
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(Color(red: 0.73, green: 0.36, blue: 0.18).opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(article.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)
                            .lineLimit(2)

                        Text(article.subtitle)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.secondary)
                            .lineLimit(2)
                    }

                    Spacer(minLength: 8)

                    readingPill(article.duration, tint: Color(red: 0.73, green: 0.36, blue: 0.18))
                }
                .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .cardBackground()
            }
        }

    }

    private func metricTile(title: String, value: String) -> some View {

        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(Color.secondary)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .cardBackground()

    }

    private func readingPill(_ text: String, tint: Color) -> some View {

        Text(text)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(tint.opacity(0.12))
            )

    }

}

private extension View {

    func cardBackground() -> some View {
        background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
        )
    }

}

#Preview {
    NavigationStack {
        ReadView()
    }
}
