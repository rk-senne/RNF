import SwiftUI
import WatchConnectivity

@main
struct RNFWatchApp: App {
    @StateObject private var watchState = WatchAppState()
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            WatchHabitListView(state: watchState)
                .onAppear {
                    appDelegate.configure(watchState: watchState)
                }
        }
    }
}

// MARK: - Watch App State

@MainActor
final class WatchAppState: ObservableObject {
    @Published var snapshot: WatchDailySnapshot = WatchDailySnapshot(
        date: Date(), level: 1, streak: 0,
        dailyCompleted: 0, dailyGoal: 4, challengeDay: nil, habits: []
    )

    func update(from data: Data) {
        guard let decoded = try? JSONDecoder().decode(WatchDailySnapshot.self, from: data) else { return }
        snapshot = decoded
    }
}

// MARK: - WCSession Delegate (Watch side)

final class WatchAppDelegate: NSObject, WKApplicationDelegate, WCSessionDelegate {
    private var watchState: WatchAppState?

    func configure(watchState: WatchAppState) {
        self.watchState = watchState
        activateSession()
    }

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Activation complete — request fresh data from iPhone
        if activationState == .activated {
            session.sendMessage(["request": "snapshot"], replyHandler: nil, errorHandler: nil)
        }
    }

    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        // P21-FIX-04: Handle incoming snapshot data from iPhone
        Task { @MainActor in
            watchState?.update(from: messageData)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        // Handle dictionary messages if needed
    }
}
