import Foundation

/// Streak Shield persistence service.
/// Local-first with Supabase sync.
@MainActor
final class StreakShieldService: ObservableObject {
    
    // MARK: - Published State
    
    @Published private(set) var equippedShields: Int = 0
    
    // MARK: - Dependencies
    
    private let supabase: SupabaseService
    private let forgeTokenService: ForgeTokenService
    private let userDefaults: UserDefaults
    
    // MARK: - Keys
    
    private static let shieldsKey = "rnf_streak_shields_equipped"
    
    // MARK: - Init
    
    init(
        supabase: SupabaseService = .shared,
        forgeTokenService: ForgeTokenService,
        userDefaults: UserDefaults = .standard
    ) {
        self.supabase = supabase
        self.forgeTokenService = forgeTokenService
        self.userDefaults = userDefaults
        loadLocal()
    }
    
    // MARK: - Public API
    
    /// Attempt to equip a shield. Spends Forge Tokens if successful.
    /// Returns true if shield was equipped.
    @discardableResult
    func equipShield() -> Bool {
        guard StreakShieldSystem.canEquipShield(
            equippedShields: equippedShields,
            forgeTokenBalance: forgeTokenService.balance
        ) else { return false }
        
        let spent = forgeTokenService.spend(
            amount: StreakShieldSystem.shieldCost,
            reason: "Streak Shield equipped"
        )
        guard spent else { return false }
        
        equippedShields = StreakShieldSystem.equipShield(currentShields: equippedShields)
        saveLocal()
        return true
    }
    
    /// Consume a shield when a day is missed. Called by streak evaluation.
    /// Returns true if streak was protected.
    @discardableResult
    func consumeShieldIfAvailable() -> Bool {
        let (protected, remaining) = StreakShieldSystem.evaluateMissedDay(
            equippedShields: equippedShields
        )
        if protected {
            equippedShields = remaining
            saveLocal()
        }
        return protected
    }
    
    /// Sync shield count from remote on app launch.
    func syncFromRemote(userID: UUID) async {
        guard let client = supabase.client else { return }
        
        do {
            struct ShieldRow: Decodable {
                let equipped_shields: Int
            }
            let rows: [ShieldRow] = try await client
                .from("users")
                .select("equipped_shields")
                .eq("id", value: userID.uuidString)
                .limit(1)
                .execute()
                .value
            
            if let remote = rows.first, remote.equipped_shields != equippedShields {
                equippedShields = remote.equipped_shields
                saveLocal()
            }
        } catch {
            RNFLogger.auth.error("StreakShieldService: syncFromRemote failed — \(error.localizedDescription)")
        }
    }
    
    // MARK: - Local Persistence
    
    private func loadLocal() {
        equippedShields = userDefaults.integer(forKey: Self.shieldsKey)
    }
    
    private func saveLocal() {
        userDefaults.set(equippedShields, forKey: Self.shieldsKey)
    }
}
