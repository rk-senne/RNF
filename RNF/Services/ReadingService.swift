import Foundation

final class ReadingService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func uploadReadingProof() async {
        _ = supabase
    }

}
