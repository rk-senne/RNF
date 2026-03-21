import Foundation

final class SubscriptionService {

    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func getSubscriptionState() async {
        _ = supabase
    }

}
