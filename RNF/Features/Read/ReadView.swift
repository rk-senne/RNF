import SwiftUI
import PhotosUI
import UIKit

struct ReadView: View {

    private enum UploadState {
        case idle
        case loadingPhoto
        case ready
        case uploading
        case completed(Int)
        case failed(String)
    }

    @EnvironmentObject private var game: GameState
    @EnvironmentObject private var notifications: NotificationManager
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedImage: UIImage?
    @State private var uploadState: UploadState = .idle
    @State private var showBookNameAlert = false
    @State private var bookNameInput = ""

    private let readingEngine = ReadingEngine()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                currentBookSection
                proofUploadCard
                readingStatsRow
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .navigationTitle("Read")
        .navigationBarTitleDisplayMode(.large)
        .alert("Current Book", isPresented: $showBookNameAlert) {
            TextField("Book title", text: $bookNameInput)
            Button("Save") {
                guard !bookNameInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                ReadingProfileService.setCurrentBook(bookNameInput.trimmingCharacters(in: .whitespaces))
                bookNameInput = ""
            }
            Button("Cancel", role: .cancel) { bookNameInput = "" }
        }
        .task {
            readingEngine.configure(gameState: game)
        }
        .onChange(of: selectedPhoto) { _, newPhoto in
            Task {
                await loadSelectedPhoto(newPhoto)
            }
        }
    }

    // MARK: - Current Book

    private var currentBookSection: some View {
        let profile = ReadingProfileService.load()
        return Group {
            if profile.currentBook.isEmpty {
                Button {
                    showBookNameAlert = true
                } label: {
                    Label("Set current book", systemImage: "book.closed")
                        .font(RNFFont.bodyBold)
                        .foregroundStyle(RNFColors.quest)
                }
                .accessibilityLabel("Set the book you are currently reading")
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "book.fill")
                        .foregroundStyle(RNFColors.quest)
                    Text(profile.currentBook)
                        .font(RNFFont.bodyBold)
                        .lineLimit(1)
                    Spacer()
                    bookCompletionButton(profile: profile)
                }
                .padding(12)
                .cardBackground()
            }
        }
    }

    @ViewBuilder
    private func bookCompletionButton(profile: ReadingProfile) -> some View {
        Button {
            ReadingProfileService.completeBook()
            RNFHaptics.success()
            notifications.showToast(.xpGain(50))
        } label: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(RNFColors.success)
        }
        .accessibilityLabel("Mark current book as completed")
    }

    // MARK: - Proof Upload

    private var proofUploadCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .clipped()
            }

            uploadControls
        }
        .padding(16)
        .cardBackground()
    }

    private var uploadControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label(photoButtonTitle, systemImage: "photo.on.rectangle.angled")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isUploading)
                .accessibilityLabel("Choose photo proof")

                Button {
                    Task {
                        await submitProof()
                    }
                } label: {
                    Label(submitButtonTitle, systemImage: submitButtonIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedImageData == nil || isUploading || isLoadingPhoto)
                .accessibilityLabel(selectedImageData == nil ? "Submit disabled, choose photo first" : "Submit reading proof")
            }

            uploadStatus
        }
    }

    @ViewBuilder
    private var uploadStatus: some View {
        switch uploadState {
        case .idle:
            EmptyView()
        case .loadingPhoto:
            Label("Loading photo", systemImage: "hourglass")
                .font(RNFFont.caption)
                .foregroundStyle(Color.secondary)
        case .ready:
            Label("Proof ready", systemImage: "checkmark.circle.fill")
                .font(RNFFont.caption)
                .foregroundStyle(RNFColors.success)
        case .uploading:
            Label("Uploading proof", systemImage: "arrow.up.circle.fill")
                .font(RNFFont.caption)
                .foregroundStyle(Color.secondary)
        case .completed(let xp):
            Label("Reading Complete +\(xp) XP", systemImage: "checkmark.seal.fill")
                .font(RNFFont.caption)
                .foregroundStyle(RNFColors.success)
        case .failed(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(RNFFont.caption)
                .foregroundStyle(RNFColors.destructive)
        }
    }

    // MARK: - Stats

    private var readingStatsRow: some View {
        let profile = ReadingProfileService.load()
        return HStack(spacing: 10) {
            readingPill("\(profile.totalPages) pages", tint: RNFColors.quest)
            readingPill("\(profile.booksCompleted) books", tint: RNFColors.success)
            readingPill("\(profile.readingStreak)🔥", tint: RNFColors.streak)
        }
    }

    // MARK: - Helpers

    private func readingPill(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(RNFFont.pill)
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

    private var photoButtonTitle: String {
        selectedImage == nil ? "Choose Photo" : "Change"
    }

    private var submitButtonTitle: String {
        isUploading ? "Uploading" : "Submit"
    }

    private var submitButtonIcon: String {
        isUploading ? "hourglass" : "arrow.up.circle.fill"
    }

    private var isLoadingPhoto: Bool {
        if case .loadingPhoto = uploadState {
            return true
        }
        return false
    }

    private var isUploading: Bool {
        if case .uploading = uploadState {
            return true
        }
        return false
    }

    private func loadSelectedPhoto(_ photo: PhotosPickerItem?) async {
        guard let photo else {
            return
        }

        uploadState = .loadingPhoto

        do {
            guard
                let data = try await photo.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                selectedImageData = nil
                selectedImage = nil
                uploadState = .failed("Photo could not be loaded")
                return
            }

            selectedImageData = data
            selectedImage = image
            uploadState = .ready
        } catch {
            selectedImageData = nil
            selectedImage = nil
            uploadState = .failed("Photo could not be loaded")
        }
    }

    private func submitProof() async {
        guard let selectedImageData else {
            uploadState = .failed("Choose a photo first")
            return
        }

        uploadState = .uploading

        if let result = await readingEngine.completeReading(imageData: selectedImageData) {
            uploadState = .completed(result.xpAwarded)
            RNFHaptics.success()
        } else {
            uploadState = .failed("Proof could not be uploaded")
        }
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
                .strokeBorder(RNFColors.borderSubtle, lineWidth: 1)
        )
    }

}

#Preview {
    NavigationStack {
        ReadView()
            .environmentObject(GameState())
    }
}
