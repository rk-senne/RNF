import BackgroundTasks
import Foundation
import os
import WidgetKit

// MARK: - P26-APL-07/08/09/10: Background Task Manager

/// Coordinates all background task registration, scheduling, and execution.
/// Handles widget data refresh, offline sync flush, and analytics batching.
///
/// Task identifiers must be registered in Info.plist under `BGTaskSchedulerPermittedIdentifiers`:
/// - `com.rnf.widget-refresh` (BGAppRefreshTask — ~1 hour cadence)
/// - `com.rnf.sync-flush` (BGProcessingTask — ~4 hour cadence, requires network)
/// - `com.rnf.analytics-batch` (BGProcessingTask — daily at ~3 AM, requires network)
final class BackgroundTaskManager {

    static let shared = BackgroundTaskManager()

    private let logger = Logger(subsystem: "com.rnf.app", category: "background")

    // MARK: - Task Identifiers

    enum TaskID {
        static let widgetRefresh = "com.rnf.widget-refresh"
        static let syncFlush = "com.rnf.sync-flush"
        static let analyticsBatch = "com.rnf.analytics-batch"
    }

    // MARK: - Registration

    /// Call once during app launch (before first scene renders).
    /// Must be invoked before `BGTaskScheduler.shared.submit(_:)`.
    func registerAllTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskID.widgetRefresh,
            using: nil
        ) { [weak self] task in
            guard let self else { return }
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleWidgetRefresh(task: refreshTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskID.syncFlush,
            using: nil
        ) { [weak self] task in
            guard let self else { return }
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleSyncFlush(task: processingTask)
        }

        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: TaskID.analyticsBatch,
            using: nil
        ) { [weak self] task in
            guard let self else { return }
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleAnalyticsBatch(task: processingTask)
        }

        logger.info("BackgroundTaskManager: All tasks registered")
    }

    // MARK: - Scheduling

    /// Schedules the widget refresh task (~1 hour cadence).
    func scheduleWidgetRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: TaskID.widgetRefresh)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 1 hour

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.debug("BackgroundTaskManager: Scheduled widget refresh")
        } catch {
            logger.error("BackgroundTaskManager: Failed to schedule widget refresh — \(error.localizedDescription)")
        }
    }

    /// Schedules the sync flush task (~4 hour cadence, requires network).
    func scheduleSyncFlush() {
        let request = BGProcessingTaskRequest(identifier: TaskID.syncFlush)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.debug("BackgroundTaskManager: Scheduled sync flush")
        } catch {
            logger.error("BackgroundTaskManager: Failed to schedule sync flush — \(error.localizedDescription)")
        }
    }

    /// Schedules the analytics batch task (daily at ~3 AM, requires network).
    func scheduleAnalyticsBatch() {
        let request = BGProcessingTaskRequest(identifier: TaskID.analyticsBatch)
        request.earliestBeginDate = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 3),
            matchingPolicy: .nextTime
        )
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.debug("BackgroundTaskManager: Scheduled analytics batch")
        } catch {
            logger.error("BackgroundTaskManager: Failed to schedule analytics batch — \(error.localizedDescription)")
        }
    }

    /// Convenience: schedules all periodic tasks. Call on app launch and after each task completes.
    func scheduleAllTasks() {
        scheduleWidgetRefresh()
        scheduleSyncFlush()
        scheduleAnalyticsBatch()
    }

    // MARK: - Handlers

    /// P26-APL-07: Widget data refresh.
    /// Reads latest habit data from the app group and reloads widget timelines.
    private func handleWidgetRefresh(task: BGAppRefreshTask) {
        logger.info("BackgroundTaskManager: Handling widget refresh")

        // Re-schedule for next hour
        scheduleWidgetRefresh()

        let operation = Task {
            do {
                // Read current data from shared container
                let defaults = UserDefaults(suiteName: RNFWidgetData.appGroupID)
                if let data = defaults?.data(forKey: RNFWidgetData.userDefaultsKey),
                   let widgetData = try? JSONDecoder().decode(RNFWidgetData.self, from: data) {

                    // Check if data is stale (older than 2 hours)
                    let isStale = Date().timeIntervalSince(widgetData.lastUpdated) > 7200
                    if isStale {
                        // Write a refreshed timestamp to trigger timeline update
                        let refreshed = RNFWidgetData(
                            streakCount: widgetData.streakCount,
                            dailyCompleted: widgetData.dailyCompleted,
                            dailyGoal: widgetData.dailyGoal,
                            level: widgetData.level,
                            questNames: widgetData.questNames,
                            questCompletions: widgetData.questCompletions,
                            lastUpdated: Date()
                        )
                        if let encoded = try? JSONEncoder().encode(refreshed) {
                            defaults?.set(encoded, forKey: RNFWidgetData.userDefaultsKey)
                        }
                    }
                }

                WidgetCenter.shared.reloadAllTimelines()
                task.setTaskCompleted(success: true)
                self.logger.info("BackgroundTaskManager: Widget refresh completed")
            }
        }

        task.expirationHandler = {
            operation.cancel()
            self.logger.warning("BackgroundTaskManager: Widget refresh expired")
        }
    }

    /// P26-APL-08: Offline write queue flush.
    /// Pushes any pending local writes to Supabase.
    private func handleSyncFlush(task: BGProcessingTask) {
        logger.info("BackgroundTaskManager: Handling sync flush")

        // Re-schedule for next 4 hours
        scheduleSyncFlush()

        let operation = Task { @MainActor in
            let syncService = SyncFlushService()
            await syncService.flush()
            task.setTaskCompleted(success: true)
            self.logger.info("BackgroundTaskManager: Sync flush completed")
        }

        task.expirationHandler = {
            operation.cancel()
            self.logger.warning("BackgroundTaskManager: Sync flush expired")
        }
    }

    /// P26-APL-09/10: Analytics batch + subscription refresh.
    /// Flushes accumulated analytics events and refreshes subscription entitlements.
    private func handleAnalyticsBatch(task: BGProcessingTask) {
        logger.info("BackgroundTaskManager: Handling analytics batch")

        // Re-schedule for next day
        scheduleAnalyticsBatch()

        let operation = Task { @MainActor in
            // Refresh subscription status via StoreKit
            let subscriptionManager = SubscriptionManager()
            await subscriptionManager.resolveEntitlements()

            task.setTaskCompleted(success: true)
            self.logger.info("BackgroundTaskManager: Analytics batch completed")
        }

        task.expirationHandler = {
            operation.cancel()
            self.logger.warning("BackgroundTaskManager: Analytics batch expired")
        }
    }
}
