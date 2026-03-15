import Foundation
import Supabase

class SupabaseManager {

    static let shared = SupabaseManager()

    let client = SupabaseClient(
        supabaseURL: URL(string: "https://jajeydbxuhzcaufkrpss.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImphamV5ZGJ4dWh6Y2F1ZmtycHNzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM0MjEyMzksImV4cCI6MjA4ODk5NzIzOX0.8FuV73QO5tRSbhVlLcogAxtad8hBpRyB1lBczKeuxLo"
    )
}
