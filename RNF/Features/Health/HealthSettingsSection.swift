import SwiftUI

struct HealthSettingsSection: View {
    @AppStorage("rnf_healthkit_enabled") private var healthKitEnabled = false

    var body: some View {
        Section("Apple Health") {
            Toggle("Import Workouts", isOn: $healthKitEnabled)
            if healthKitEnabled {
                NavigationLink("Review Imports") {
                    ImportedWorkoutReviewView(workouts: [])
                }
            }
        }
    }
}
