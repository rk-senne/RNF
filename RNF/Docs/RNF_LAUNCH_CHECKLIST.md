# RNF Launch Checklist

All 260 code tasks are complete. This document covers what remains before the app ships.

---

## 1. Development Environment Setup

```bash
# Install iOS 18.5 simulator runtime
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -downloadPlatform iOS

# Set Xcode as active developer directory (requires admin)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Create a simulator
xcrun simctl create "iPhone16" "iPhone 16" iOS18.5

# Verify build
xcodebuild -scheme RNF -destination 'platform=iOS Simulator,name=iPhone16' build
```

---

## 2. Xcode Project Configuration

### Targets to wire in Xcode:

| Target | Source Directory | Notes |
|--------|-----------------|-------|
| RNFWidget | `RNFWidget/` | WidgetKit extension, iOS |
| RNFWatch | `RNFWatch/` | watchOS app target |

### Entitlements to assign:

| Target | File | Capability |
|--------|------|-----------|
| RNF (main app) | `RNF/RNF.entitlements` | App Groups (`group.com.rnf.shared`) |
| RNFWidget | `RNFWidget/RNFWidget.entitlements` | App Groups (`group.com.rnf.shared`) |
| RNF (main app) | — | HealthKit (add in Signing & Capabilities) |

### Info.plist keys to add:

```xml
<key>NSHealthShareUsageDescription</key>
<string>RNF reads your workout data to credit daily progress.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>RNF does not write to Apple Health.</string>
```

### Shared files between targets:

These files need to be included in both main app and widget targets:
- `RNFWidget/RNFWidgetData.swift`

These files need to be shared between main app and Watch:
- `RNF/Models/ApplePlatform.swift` (WatchDailySnapshot, WatchHabitSummary, message DTOs)

---

## 3. Supabase Setup

### Create project:
1. Go to https://supabase.com/dashboard
2. Create new project
3. Copy project URL and anon key

### Configure app:
Update `RNF/Core/AppConfig.swift` or `RNF/Services/SupabaseService.swift` with:
- `supabaseURL`
- `supabaseKey` (anon/public key)

### Run migrations in order:
```bash
# From project root, apply each migration
supabase db push
# Or manually via SQL editor in order: 000 through 014
```

Migration files:
```
supabase/migrations/000_enable_extensions.sql
supabase/migrations/001_create_users.sql
supabase/migrations/002_create_habits.sql
supabase/migrations/003_create_daily_logs.sql
supabase/migrations/004_create_habit_completions.sql
supabase/migrations/005_create_challenges.sql
supabase/migrations/006_create_workouts.sql
supabase/migrations/007_create_reading_uploads.sql
supabase/migrations/008_create_subscriptions.sql
supabase/migrations/009_add_production_indexes.sql
supabase/migrations/010_enable_rls_policies.sql
supabase/migrations/011_create_boss_achievement_mastery.sql
supabase/migrations/012_create_social_tables.sql
supabase/migrations/013_enable_rls_new_tables.sql
supabase/migrations/014_create_health_imports.sql
```

### Verify:
- RLS policies active on all tables
- Authenticated users can only access own data
- Storage bucket `reading-proof` exists with authenticated upload policy

---

## 4. StoreKit Configuration

1. Create `RNF.storekit` configuration file in Xcode
2. Add subscription products matching `SubscriptionService` product IDs
3. Configure in App Store Connect for production

---

## 5. Run Tests

```bash
xcodebuild test \
  -scheme RNF \
  -destination 'platform=iOS Simulator,name=iPhone16' \
  -resultBundlePath TestResults.xcresult
```

Test files (25):
- `RNFTests/` — unit and integration tests
- Covers: XP, daily logs, challenges, progression, workouts, reading, perks, quests, calendar, skill trees, evolution, auth scoping, idempotency, ViewModel failures, date normalization, migration structure, feature gates, boss system, achievements, social, Apple platform

---

## 6. Manual QA Pass

### Critical flows to test:
- [ ] Sign up → onboarding → notification setup → commitment → daily progress
- [ ] Complete all daily habits → streak increment → XP award → level up
- [ ] Workout timer → completion → daily log update
- [ ] Reading proof upload → daily log update
- [ ] Miss a day → forgiveness prompt → streak preservation
- [ ] 90-day challenge completion → restart flow
- [ ] Guest tryout → account creation gate
- [ ] Offline habit completion → reconnect → sync flush
- [ ] App kill → relaunch → session restore
- [ ] Widget displays correct streak/progress
- [ ] Boss damage on habit completion (Level 10+ users)
- [ ] Achievement unlock toast
- [ ] Theme toggle (light/dark/system)
- [ ] Export JSON/CSV → share sheet

---

## 7. App Store Preparation

### Required assets:
- [ ] App icon (1024x1024 for App Store, plus all sizes in `AppIcon.appiconset`)
- [ ] Screenshots (6.7", 6.5", 5.5" if supporting older devices)
- [ ] App description
- [ ] Privacy policy URL
- [ ] App category: Health & Fitness

### App Store Connect:
- [ ] Create app listing
- [ ] Configure subscription group
- [ ] Submit privacy nutrition labels
- [ ] Enable in-app purchases

---

## 8. TestFlight

```bash
# Archive
xcodebuild archive \
  -scheme RNF \
  -archivePath RNF.xcarchive \
  -destination 'generic/platform=iOS'

# Export
xcodebuild -exportArchive \
  -archivePath RNF.xcarchive \
  -exportPath ./export \
  -exportOptionsPlist ExportOptions.plist

# Upload (or use Xcode Organizer)
xcrun altool --upload-app -f ./export/RNF.ipa -t ios -u APPLE_ID -p APP_SPECIFIC_PASSWORD
```

---

## 9. Post-Launch Monitoring

- Enable Supabase dashboard alerts for error rates
- Monitor analytics events for funnel drop-off
- Watch crash reports in Xcode Organizer
- Review App Store rating prompt timing (90-day cooldown)

---

## Architecture Reference

```
RNF/
├── App/            → App entry point, theme application
├── Core/           → Engines, state management, logger, config
├── Models/         → Codable data models
├── Systems/        → Pure logic (XP, perks, boss, feature gates, mastery)
├── Services/       → Supabase persistence, HealthKit, Watch, export
├── ViewModels/     → Published state for views
├── Features/       → SwiftUI screens by domain
├── Components/     → Reusable UI components
├── DesignSystem/   → Colors, typography, spacing, animations
├── Extensions/     → Date helpers, accessibility extensions
├── Navigation/     → Tab routing
RNFWidget/          → iOS home screen widgets
RNFWatch/           → watchOS companion app
RNFTests/           → Unit + integration tests
supabase/migrations/ → PostgreSQL schema
```
