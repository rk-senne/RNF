# RNF Security Specification

Production-readiness reference:

See `RNF_PRODUCTION_READINESS_SPEC.md` for required auth, RLS, secret handling, and user-isolation rules. If the two documents conflict, the stricter security rule applies.

---

Security ensures users cannot access or modify other users' data.

---

# Row Level Security (Supabase)

All tables must enforce RLS.

Policy rule:

auth.uid() = user_id

---

# Protected Tables

users  
daily_logs  
habit_completions  
reading_uploads  
subscriptions  

---

# Storage Security

Reading proof images stored in:

bucket: reading-proof

Path format:

reading-proof/{user_id}/{date}.jpg

Access rule:

users can only access their own folder.

---

# Local Validation Notes

Validated against service-layer code.

Row ownership:

Daily log reads include `user_id` filters.

Habit completion lookup includes `user_id`, `habit_id`, and `date` filters.

Calendar month reads include `user_id` filters.

Active challenge reads include `user_id` and `status` filters.

Subscription sync updates include a `user_id` filter.

Reading uploads write `reading_uploads.user_id` from the active caller-supplied user id.

Storage path:

`ReadingService` stores proof images under:

reading-proof/{user_id}/{yyyy-MM-dd}.jpg

This matches the documented storage path assumption.

RLS dependency:

Some write paths update by a row id returned from a prior user-scoped read. Supabase RLS must still enforce ownership on writes so clients cannot mutate rows they did not read legitimately.

Required table policy shape:

users.id = auth.uid()

All user-owned tables:

auth.uid() = user_id

Required storage policy shape:

The first folder segment must equal the authenticated user's id.

---

# Authentication Security

Passwords handled only by Supabase Auth.

No password storage inside RNF database.

Sessions stored securely in Keychain.

---

# API Rules

Service layer validates:

user session exists  
user_id matches auth.uid()

---

# Caller-Supplied User ID Inventory

Production service calls should prefer authenticated methods that resolve the current user through `AuthProviding`. Broad `userId` overloads may remain only when the caller's ID is already derived from Supabase Auth or when the overload is an internal helper behind an authenticated wrapper.

Allowed current exceptions:

| Caller | Service path | Reason |
| --- | --- | --- |
| `AppStateManager.resolveLaunchState` | `ChallengeService.getActiveChallenge(userId:)`, `DailyLogService.fetchTodayLog(userId:date:)`, `DailyLogService.createDailyLog(userId:date:)` | The ID comes directly from `AuthService.restoreSession().user.id` in the same flow. |
| `AuthService.bootstrapProfile` | `users` upsert | The bootstrap profile ID comes from the Supabase auth result/session being created or restored. |
| Authenticated wrapper methods in `DailyLogService`, `ChallengeService`, `WorkoutService`, `ReadingService`, `SubscriptionService`, and `UserService` | Internal calls to matching `userId` overloads | The ID is resolved through `authProvider.requireCurrentUserID()` before delegation. |
| Internal service composition after a verified service entry point | Daily-log create/fetch/update helpers, reading proof fetch, subscription update helpers | The ID is passed through the same call chain after the authenticated entry point resolves it. |

Production paths that still need narrowing in Phase 16 follow-up tasks:

| Caller | Current source of `userId` | Service path |
| --- | --- | --- |
| `ContentView.refreshChallenge` | `game.profile.id` | `ChallengeEngine.loadActiveChallenge(userId:)` |
| `AscensionView.loadActiveChallenge`, `useForgiveness`, and `advanceChallengeIfNeeded` | `game.profile.id` | `ChallengeEngine` methods and downstream `ChallengeService`, `DailyLogService`, `UserService`, and `SkillTreeService` calls |
| `ProgressionEngine.processHabitCompletion` | `ProgressionInput.profile.id` | `DailyLogService.updateStatus(userId:date:)` and skill-tree/profile persistence paths |
| `WorkoutEngine.completeWorkout` | `gameState.profile.id` / `updatedProfile.id` | `WorkoutService`, `DailyLogService`, and `ChallengeEngine` calls |
| `ReadingEngine.completeReading` | `gameState.profile.id` / `updatedProfile.id` | `ReadingService`, `DailyLogService`, and `ChallengeEngine` calls |
| `SubscriptionManagementView.syncSubscription` | injected optional `userId` view parameter | `SubscriptionService.syncSubscription(userId:)` |
| `SkillTreeService.activePerks` and unlock helpers | `profile.id` | `fetchUserUnlocks(userId:)` and unlock persistence |

Follow-up implementation rule:

`P16-AUTH-02` and `P16-AUTH-03` should either route these production paths through authenticated no-argument service methods or validate that any supplied `userId` matches the current authenticated user before touching user-owned data.

---

# Rate Limiting

Login attempts limited.

Recommended:

5 failed attempts → temporary lock.

---

# Data Validation

All writes must validate:

XP values positive  
habit IDs valid  
date format correct

---

# Production Security Checklist

Before launch:

Enable RLS for every protected table  
Enable storage policies for `reading-proof`  
Enable API rate limiting  
Audit database permissions
