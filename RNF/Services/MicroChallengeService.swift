import Foundation

// P24-GRO-10: Micro-challenge system
// Short-lived social challenges between friends

@MainActor
final class MicroChallengeService: ObservableObject {

    // MARK: - Types

    enum ChallengeStatus: String, Codable {
        case pending
        case active
        case completed
        case expired
    }

    struct MicroChallenge: Codable, Identifiable {
        let id: UUID
        let creator_id: UUID
        let title: String
        let description: String
        let duration_hours: Int
        let created_at: Date
        var expires_at: Date
        var status: ChallengeStatus
        var participants: [Participant]

        init(creatorID: UUID, title: String, description: String, durationHours: Int) {
            self.id = UUID()
            self.creator_id = creatorID
            self.title = title
            self.description = description
            self.duration_hours = durationHours
            self.created_at = Date()
            self.expires_at = Calendar.current.date(
                byAdding: .hour, value: durationHours, to: Date()
            ) ?? Date()
            self.status = .pending
            self.participants = []
        }
    }

    struct Participant: Codable, Identifiable {
        let id: UUID
        let user_id: UUID
        let display_name: String?
        var score: Int
        var joined_at: Date

        init(userID: UUID, displayName: String?) {
            self.id = UUID()
            self.user_id = userID
            self.display_name = displayName
            self.score = 0
            self.joined_at = Date()
        }
    }

    struct ChallengeResult: Codable {
        let challenge_id: UUID
        let winner_id: UUID?
        let final_scores: [UUID: Int]
    }

    // MARK: - Published State

    @Published private(set) var activeChallenges: [MicroChallenge] = []
    @Published private(set) var completedChallenges: [MicroChallenge] = []

    // MARK: - Dependencies

    private let supabase: SupabaseService

    // MARK: - Init

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    // MARK: - Public API

    /// Create a new micro-challenge
    func create(
        creatorID: UUID,
        title: String,
        description: String,
        durationHours: Int = 24
    ) async -> RNFServiceWriteResult<MicroChallenge> {
        var challenge = MicroChallenge(
            creatorID: creatorID,
            title: title,
            description: description,
            durationHours: durationHours
        )

        // Creator auto-joins
        let creatorParticipant = Participant(userID: creatorID, displayName: nil)
        challenge.participants.append(creatorParticipant)
        challenge.status = .active

        activeChallenges.append(challenge)

        guard let client = supabase.client else {
            return .savedLocallyOnly(challenge, error: .networkUnavailable)
        }

        do {
            let created: MicroChallenge = try await client
                .from("micro_challenges")
                .insert(challenge)
                .select()
                .single()
                .execute()
                .value
            return .savedRemotely(created)
        } catch {
            RNFLogger.auth.error("MicroChallengeService: create failed — \(error.localizedDescription)")
            return .savedLocallyOnly(challenge, error: .unknown)
        }
    }

    /// Join an existing micro-challenge
    func join(challengeID: UUID, userID: UUID, displayName: String?) async -> Bool {
        guard let index = activeChallenges.firstIndex(where: { $0.id == challengeID }) else {
            return false
        }

        let participant = Participant(userID: userID, displayName: displayName)
        activeChallenges[index].participants.append(participant)

        guard let client = supabase.client else { return true }

        do {
            try await client
                .from("micro_challenge_participants")
                .insert(participant)
                .execute()
            return true
        } catch {
            RNFLogger.auth.error("MicroChallengeService: join failed — \(error.localizedDescription)")
            return true // Saved locally
        }
    }

    /// Update a participant's score in a challenge
    func updateScore(challengeID: UUID, userID: UUID, scoreIncrement: Int) async {
        guard let challengeIndex = activeChallenges.firstIndex(where: { $0.id == challengeID }),
              let participantIndex = activeChallenges[challengeIndex].participants.firstIndex(where: { $0.user_id == userID })
        else { return }

        activeChallenges[challengeIndex].participants[participantIndex].score += scoreIncrement

        guard let client = supabase.client else { return }

        do {
            struct ScoreUpdate: Encodable {
                let score: Int
            }
            let newScore = activeChallenges[challengeIndex].participants[participantIndex].score
            try await client
                .from("micro_challenge_participants")
                .update(ScoreUpdate(score: newScore))
                .eq("user_id", value: userID.uuidString)
                .eq("challenge_id", value: challengeID.uuidString)
                .execute()
        } catch {
            RNFLogger.auth.error("MicroChallengeService: updateScore failed — \(error.localizedDescription)")
        }
    }

    /// Resolve winner when challenge expires or completes
    func resolveWinner(challengeID: UUID) async -> ChallengeResult? {
        guard let index = activeChallenges.firstIndex(where: { $0.id == challengeID }) else {
            return nil
        }

        var challenge = activeChallenges[index]
        challenge.status = .completed

        let winner = challenge.participants.max(by: { $0.score < $1.score })
        var finalScores: [UUID: Int] = [:]
        for participant in challenge.participants {
            finalScores[participant.user_id] = participant.score
        }

        let result = ChallengeResult(
            challenge_id: challengeID,
            winner_id: winner?.user_id,
            final_scores: finalScores
        )

        // Move to completed
        activeChallenges.remove(at: index)
        completedChallenges.append(challenge)

        // Sync to remote
        if let client = supabase.client {
            do {
                struct StatusUpdate: Encodable {
                    let status: String
                    let winner_id: String?
                }
                try await client
                    .from("micro_challenges")
                    .update(StatusUpdate(
                        status: ChallengeStatus.completed.rawValue,
                        winner_id: winner?.user_id.uuidString
                    ))
                    .eq("id", value: challengeID.uuidString)
                    .execute()
            } catch {
                RNFLogger.auth.error("MicroChallengeService: resolveWinner sync failed — \(error.localizedDescription)")
            }
        }

        return result
    }

    /// Fetch active challenges from remote
    func fetchActive(userID: UUID) async {
        guard let client = supabase.client else { return }

        do {
            let challenges: [MicroChallenge] = try await client
                .from("micro_challenges")
                .select()
                .eq("status", value: ChallengeStatus.active.rawValue)
                .execute()
                .value

            activeChallenges = challenges.filter { challenge in
                challenge.participants.contains(where: { $0.user_id == userID })
                    || challenge.creator_id == userID
            }
        } catch {
            RNFLogger.auth.error("MicroChallengeService: fetchActive failed — \(error.localizedDescription)")
        }
    }
}
