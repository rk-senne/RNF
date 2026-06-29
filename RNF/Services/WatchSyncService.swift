import Foundation
import WatchConnectivity

final class WatchSyncService: NSObject, WCSessionDelegate {

    static let shared = WatchSyncService()

    private var session: WCSession?
    var onHabitCompletion: ((WatchHabitCompletionMessage) -> Void)?
    var onWorkoutAction: ((WatchWorkoutMessage) -> Void)?

    override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendSnapshot(_ snapshot: WatchDailySnapshot) {
        guard let session, session.isReachable else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        session.sendMessageData(data, replyHandler: nil, errorHandler: nil)
    }

    func configureHandlers(messageHandler: WatchMessageHandler, userId: UUID, gameState: GameState) {
        onHabitCompletion = { message in
            Task { @MainActor in
                let success = await messageHandler.handleHabitCompletion(message, userId: userId)
                if success {
                    let snapshot = WatchSnapshotGenerator.generate(from: gameState)
                    self.sendSnapshot(snapshot)
                }
            }
        }
        onWorkoutAction = { message in
            Task { @MainActor in
                _ = await messageHandler.handleWorkoutAction(message, userId: userId)
            }
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        if let msg = try? JSONDecoder().decode(WatchHabitCompletionMessage.self, from: messageData) {
            onHabitCompletion?(msg)
        } else if let msg = try? JSONDecoder().decode(WatchWorkoutMessage.self, from: messageData) {
            onWorkoutAction?(msg)
        }
    }
}
