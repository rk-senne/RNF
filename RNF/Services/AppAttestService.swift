import Foundation
import DeviceCheck
import CryptoKit
import os

// MARK: - P26-APL-26/27/28/29: App Attest for Leaderboard Integrity

/// Uses DCAppAttestService to generate attestation keys and assertions for
/// securing leaderboard submissions. Degrades gracefully on unsupported devices.
@MainActor
final class AppAttestService: ObservableObject {

    // MARK: - Types

    enum AttestError: Error, LocalizedError {
        case notSupported
        case keyGenerationFailed(underlying: Error)
        case attestationFailed(underlying: Error)
        case assertionFailed(underlying: Error)
        case noKeyAvailable
        case serverValidationFailed
        case challengeUnavailable

        var errorDescription: String? {
            switch self {
            case .notSupported: return "App Attest is not supported on this device."
            case .keyGenerationFailed(let e): return "Key generation failed: \(e.localizedDescription)"
            case .attestationFailed(let e): return "Attestation failed: \(e.localizedDescription)"
            case .assertionFailed(let e): return "Assertion failed: \(e.localizedDescription)"
            case .noKeyAvailable: return "No attestation key available. Please re-register."
            case .serverValidationFailed: return "Server rejected attestation."
            case .challengeUnavailable: return "Could not obtain server challenge."
            }
        }
    }

    /// Result of an assertion — the raw assertion data to send with a request.
    struct AssertionResult {
        let assertionData: Data
        let clientDataHash: Data
        let keyID: String
    }

    // MARK: - Properties

    private let logger = Logger(subsystem: "com.rnf.app", category: "AppAttest")

    /// P26-APL-29: Whether the device supports App Attest.
    @Published private(set) var isSupported: Bool = false

    /// Whether a key has been generated and attested.
    @Published private(set) var isAttested: Bool = false

    /// Indicates fallback mode (device doesn't support attest).
    @Published private(set) var isFallbackMode: Bool = false

    private var keyID: String? {
        get { UserDefaults.standard.string(forKey: Self.keyIDStorageKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.keyIDStorageKey) }
    }

    private var keyAttested: Bool {
        get { UserDefaults.standard.bool(forKey: Self.keyAttestedKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.keyAttestedKey) }
    }

    private static let keyIDStorageKey = "rnf_app_attest_key_id"
    private static let keyAttestedKey = "rnf_app_attest_key_attested"

    // MARK: - Init

    init() {
        checkSupport()
    }

    // MARK: - P26-APL-26: Check Support & Generate Key

    /// Checks if the device supports App Attest.
    func checkSupport() {
        if #available(iOS 14.0, *) {
            isSupported = DCAppAttestService.shared.isSupported
        } else {
            isSupported = false
        }
        isFallbackMode = !isSupported
        isAttested = keyAttested && keyID != nil

        if isFallbackMode {
            logger.info("App Attest not supported — using fallback mode")
        }
    }

    /// P26-APL-26: Generate a new attestation key.
    func generateKey() async throws -> String {
        guard #available(iOS 14.0, *), isSupported else {
            throw AttestError.notSupported
        }

        let service = DCAppAttestService.shared

        do {
            let newKeyID = try await service.generateKey()
            self.keyID = newKeyID
            self.keyAttested = false
            self.isAttested = false
            logger.info("App Attest key generated: \(newKeyID.prefix(8))...")
            return newKeyID
        } catch {
            logger.error("Key generation failed: \(error.localizedDescription)")
            throw AttestError.keyGenerationFailed(underlying: error)
        }
    }

    // MARK: - P26-APL-27: Attest Key with Server Challenge

    /// Attests the generated key with a server-provided challenge.
    /// The returned attestation object should be sent to your server for verification.
    /// - Parameter challenge: Server-provided challenge data (e.g., from /api/attest/challenge)
    /// - Returns: The attestation object bytes to send to your server
    func attestKey(challenge: Data) async throws -> Data {
        guard #available(iOS 14.0, *), isSupported else {
            throw AttestError.notSupported
        }
        guard let currentKeyID = keyID else {
            throw AttestError.noKeyAvailable
        }

        let service = DCAppAttestService.shared
        let clientDataHash = Data(SHA256.hash(data: challenge))

        do {
            let attestation = try await service.attestKey(currentKeyID, clientDataHash: clientDataHash)
            keyAttested = true
            isAttested = true
            logger.info("Key attested successfully")
            return attestation
        } catch {
            // Key may be invalid — clear and require re-generation
            logger.error("Attestation failed: \(error.localizedDescription)")
            clearKey()
            throw AttestError.attestationFailed(underlying: error)
        }
    }

    // MARK: - P26-APL-28: Generate Assertion for Leaderboard Submissions

    /// Generates an assertion for a specific request payload.
    /// Use this to sign leaderboard score submissions.
    /// - Parameter payload: The request payload to assert (e.g., JSON body of leaderboard submission)
    /// - Returns: An AssertionResult containing the assertion data and metadata
    func generateAssertion(for payload: Data) async throws -> AssertionResult {
        guard #available(iOS 14.0, *), isSupported else {
            throw AttestError.notSupported
        }
        guard let currentKeyID = keyID, keyAttested else {
            throw AttestError.noKeyAvailable
        }

        let service = DCAppAttestService.shared
        let clientDataHash = Data(SHA256.hash(data: payload))

        do {
            let assertion = try await service.generateAssertion(currentKeyID, clientDataHash: clientDataHash)
            logger.info("Assertion generated for payload (\(payload.count) bytes)")
            return AssertionResult(
                assertionData: assertion,
                clientDataHash: clientDataHash,
                keyID: currentKeyID
            )
        } catch {
            logger.error("Assertion generation failed: \(error.localizedDescription)")
            throw AttestError.assertionFailed(underlying: error)
        }
    }

    /// Convenience: Generate assertion for a leaderboard score submission.
    /// - Parameters:
    ///   - userID: The submitting user's ID
    ///   - score: The score value
    ///   - leaderboardID: The leaderboard identifier
    /// - Returns: An AssertionResult to attach to the submission request
    func assertLeaderboardSubmission(
        userID: UUID,
        score: Int,
        leaderboardID: String
    ) async throws -> AssertionResult {
        let submission: [String: Any] = [
            "user_id": userID.uuidString,
            "score": score,
            "leaderboard_id": leaderboardID,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]

        guard let payload = try? JSONSerialization.data(withJSONObject: submission) else {
            throw AttestError.assertionFailed(underlying: NSError(
                domain: "RNF", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to serialize submission"]
            ))
        }

        return try await generateAssertion(for: payload)
    }

    // MARK: - P26-APL-29: Graceful Degradation

    /// Returns whether the submission should include attestation.
    /// On unsupported devices, returns false — server should accept unattested
    /// submissions with reduced trust or rate limiting.
    var shouldAttest: Bool {
        isSupported && isAttested
    }

    /// Attempts to assert if possible, otherwise returns nil for fallback.
    /// Server should handle both attested and unattested submissions.
    func assertIfAvailable(payload: Data) async -> AssertionResult? {
        guard shouldAttest else {
            logger.info("Fallback mode — skipping attestation")
            return nil
        }

        do {
            return try await generateAssertion(for: payload)
        } catch {
            logger.warning("Assertion failed, falling back: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Key Management

    /// Clears stored key data (e.g., after failed attestation or user reset).
    func clearKey() {
        keyID = nil
        keyAttested = false
        isAttested = false
        logger.info("App Attest key cleared")
    }

    /// Full setup flow: generate key → attest with server challenge.
    /// Returns the attestation data to send to server for verification.
    func setupAndAttest(challenge: Data) async throws -> Data {
        _ = try await generateKey()
        return try await attestKey(challenge: challenge)
    }
}
