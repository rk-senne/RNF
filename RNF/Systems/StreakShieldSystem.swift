import Foundation

struct StreakShieldSystem {
    
    /// Cost in Forge Tokens to equip one shield
    static let shieldCost = 3
    
    /// Maximum shields that can be equipped at once
    static let maxEquipped = 2
    
    /// Check if a shield can be equipped (has tokens and under cap)
    static func canEquipShield(equippedShields: Int, forgeTokenBalance: Int) -> Bool {
        equippedShields < maxEquipped && forgeTokenBalance >= shieldCost
    }
    
    /// Returns the new shield count after equipping. Does NOT handle token spending.
    static func equipShield(currentShields: Int) -> Int {
        min(currentShields + 1, maxEquipped)
    }
    
    /// Determines if a missed day should be auto-protected by an equipped shield.
    /// Returns (shouldProtect: Bool, remainingShields: Int)
    static func evaluateMissedDay(equippedShields: Int) -> (shouldProtect: Bool, remainingShields: Int) {
        if equippedShields > 0 {
            return (true, equippedShields - 1)
        }
        return (false, 0)
    }
    
    /// Updated streak calculation with shield consideration.
    /// If day is missed but shield protects, streak is preserved (not incremented).
    static func updateStreakWithShield(
        currentStreak: Int,
        dailyCompleted: Int,
        dailyGoal: Int,
        dayMissed: Bool,
        equippedShields: Int
    ) -> (newStreak: Int, shieldsRemaining: Int, shieldUsed: Bool) {
        
        if !dayMissed && dailyCompleted >= dailyGoal {
            return (currentStreak + 1, equippedShields, false)
        }
        
        if dayMissed || dailyCompleted < dailyGoal {
            let (protected, remaining) = evaluateMissedDay(equippedShields: equippedShields)
            if protected {
                // Shield consumed — streak preserved but not incremented
                return (currentStreak, remaining, true)
            }
            return (0, remaining, false)
        }
        
        return (currentStreak, equippedShields, false)
    }
}
