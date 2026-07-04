import SwiftUI

/// Account deletion screen with 7-day grace period and danger zone UI.
struct AccountDeletionView: View {
    @EnvironmentObject private var game: GameState
    @StateObject private var deletionService = AccountDeletionService()
    @State private var showConfirmation = false
    @State private var confirmText = ""
    @State private var scheduledDate: Date?
    @State private var errorMessage: String?
    @State private var isProcessing = false

    private let requiredConfirmText = "DELETE"

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: RNFSpacing.sm) {
                    Label("Danger Zone", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(RNFFont.headline)

                    Text("Deleting your account will permanently remove all your data including habits, streaks, challenges, and progress. This action cannot be undone after the grace period.")
                        .font(RNFFont.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let scheduled = scheduledDate {
                Section("Scheduled Deletion") {
                    VStack(alignment: .leading, spacing: RNFSpacing.xs) {
                        Text("Your account is scheduled for deletion on:")
                            .font(RNFFont.body)
                        Text(scheduled, style: .date)
                            .font(RNFFont.headline)
                            .foregroundStyle(.red)

                        Button("Cancel Deletion") {
                            deletionService.cancelDeletion()
                            scheduledDate = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .padding(.top, RNFSpacing.xs)
                    }
                }
            } else {
                Section("Delete Account") {
                    VStack(alignment: .leading, spacing: RNFSpacing.sm) {
                        Text("Type \"\(requiredConfirmText)\" to confirm:")
                            .font(RNFFont.caption)

                        TextField("Type DELETE", text: $confirmText)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()

                        Button(role: .destructive) {
                            showConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Schedule Account Deletion")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(confirmText != requiredConfirmText || isProcessing)
                    }
                }
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(RNFFont.caption)
                }
            }
        }
        .navigationTitle("Delete Account")
        .onAppear {
            scheduledDate = deletionService.scheduledDeletionDate
        }
        .alert("Delete Account?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Schedule Deletion", role: .destructive) {
                scheduleDeletion()
            }
        } message: {
            Text("Your account will be permanently deleted after a 7-day grace period. You can cancel during this time.")
        }
    }

    private func scheduleDeletion() {
        isProcessing = true
        Task {
            do {
                let date = try await deletionService.scheduleDeletion(userId: game.profile.id)
                scheduledDate = date
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }
}
