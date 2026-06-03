import SwiftUI

struct NotificationSetupView: View {

    private let scheduler: NotificationScheduler
    private let onContinue: () -> Void

    @State private var morningTime: Date
    @State private var eveningTime: Date
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        scheduler: NotificationScheduler = NotificationScheduler(),
        morningTime: Date = Self.defaultTime(hour: 7, minute: 30),
        eveningTime: Date = Self.defaultTime(hour: 20, minute: 30),
        onContinue: @escaping () -> Void = {}
    ) {
        self.scheduler = scheduler
        self.onContinue = onContinue
        self._morningTime = State(initialValue: morningTime)
        self._eveningTime = State(initialValue: eveningTime)
    }

    var body: some View {

        VStack(alignment: .leading, spacing: 24) {
            Spacer(minLength: 24)

            VStack(alignment: .leading, spacing: 12) {
                Text("DAILY RHYTHM")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.secondary)

                Text("Set Your Rhythm")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Choose the times that frame your day with intention and reflection.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 14) {
                timePicker(
                    title: "Morning Quote",
                    icon: "sun.max.fill",
                    selection: $morningTime
                )

                timePicker(
                    title: "Evening Reflection",
                    icon: "moon.stars.fill",
                    selection: $eveningTime
                )
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: saveSchedule) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text(isSaving ? "Saving" : "Continue")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)

            Spacer(minLength: 24)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .navigationTitle("Daily Rhythm")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func timePicker(
        title: String,
        icon: String,
        selection: Binding<Date>
    ) -> some View {

        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            DatePicker(
                title,
                selection: selection,
                displayedComponents: .hourAndMinute
            )
            .font(.system(size: 16, weight: .bold, design: .rounded))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func saveSchedule() {
        guard !isSaving else {
            return
        }

        isSaving = true
        errorMessage = nil

        Task {
            do {
                let granted = try await scheduler.requestPermission()

                guard granted else {
                    isSaving = false
                    errorMessage = "Notifications are disabled for RNF."
                    return
                }

                try await scheduler.scheduleMorningNotification(
                    at: Self.timeComponents(from: morningTime)
                )
                try await scheduler.scheduleEveningNotification(
                    at: Self.timeComponents(from: eveningTime)
                )

                isSaving = false
                onContinue()
            } catch {
                isSaving = false
                errorMessage = "Unable to schedule notifications. Try again."
            }
        }
    }

    private static func defaultTime(hour: Int, minute: Int) -> Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    private static func timeComponents(from date: Date) -> DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: date)
    }

}

#Preview {
    NavigationStack {
        NotificationSetupView()
    }
}
