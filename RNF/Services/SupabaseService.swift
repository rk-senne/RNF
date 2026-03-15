import Supabase
import Foundation

final class SupabaseService {

    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {

        let supabaseURL = URL(string: "https://jajeydbxuhzcaufkrpss.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphamV5ZGJ4dWh6Y2F1ZmtycHNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MjEyMzksImV4cCI6MjA4ODk5NzIzOX0.8FuV73QO5tRSbhVlLcogAxtad8hBpRyB1lBczKeuxLo"

        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}
