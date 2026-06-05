# RNF Milestone Completion Plan

This document defines what "100% complete" means for each RNF milestone.

It is not a feature wishlist. It is a completion gate plan for turning RNF from a working MVP codebase into a reliable product, then a scalable team/project.

Current verified state:

- Task graph: 184 complete, 15 open.
- Current open work: Phase 16 architecture hardening.
- Unit tests found: 86 test functions across `RNFTests`.
- Supabase migrations found: 14 migration files.
- GitHub setup exists for PR templates, issue templates, CODEOWNERS, Dependabot, iOS build/tests, docs check, and migration check.

## Operating Rule

Do milestones in order.

```text
Architecture Hardening -> MVP Core Loop -> Private Alpha -> Public Beta -> Production v1 -> Scale/Team -> Apple Health -> Apple Watch
```

No HealthKit, watchOS, social, AI, or large gameplay expansion should start until the iPhone MVP and production-readiness gates are stable.

## Milestone 0 - Architecture And Automation Baseline

Current estimate: 70-75%.

Goal:

Make the codebase safe for repeated Builder -> Verifier implementation without architecture drift.

Already in place:

- Builder/Verifier automation.
- Task graph execution model.
- Trust scoring and LOW-streak pause.
- App shell routing through `AppStateManager`.
- ViewModels for reading and workout workflows.
- Reading and workout engines return typed results.
- Centralized day boundary policy.
- Supabase migrations and RLS docs.
- GitHub workflow and process documentation.

Missing to reach 100%:

- Finish Phase 16 architecture hardening in `task_graph.md`.
- Remove `ProgressionEngine` dependence on `GameState`.
- Narrow broad caller-supplied `userId` service paths.
- Reduce `DailyLogService` responsibilities.
- Split large SwiftUI files only after state boundaries are stable.
- Confirm CI workflows are green on GitHub, not only locally.
- Confirm branch protections are enabled for `main` and `develop`.

100% gate:

- Phase 16 is complete.
- Command-line build passes.
- Targeted unit tests pass.
- Verifier returns LOW for the final Phase 16 task.
- No new architecture audit finding is MEDIUM or HIGH.
- `task_graph.md` has a clear next phase or no open tasks.

## Milestone 1 - MVP Core Loop

Current estimate: 75-80%.

Goal:

A user can complete the RNF iPhone discipline loop from account creation through daily progress without developer assistance.

Core user journey:

1. Open app.
2. Sign up or log in.
3. Complete onboarding.
4. Start or resume the 90-day challenge.
5. See daily habits.
6. Complete a habit once per day.
7. Gain XP and stat rewards.
8. Complete workout.
9. Upload reading proof.
10. See daily log/calendar progress.
11. See profile, level, streak, stats, titles, skill/evolution progress.
12. Return next day and continue without data loss.

Already in place:

- Authentication and app-state routing.
- Daily habits/progression systems.
- XP, stats, streak, quest, skill tree, perk, and evolution systems.
- Workout and reading workflows.
- Reading-proof storage migration.
- Daily logs and habit completion migrations.
- Service, engine, and ViewModel tests for many core flows.

Missing to reach 100%:

- End-to-end manual QA checklist for the full MVP journey.
- UI tests or smoke tests for onboarding, login, daily habit, workout, reading, and profile navigation.
- Empty/loading/error states checked on every MVP screen.
- Duplicate-tap and retry behavior verified on real UI flows.
- Calendar month/history behavior verified with larger data.
- Reading proof image size/compression/upload failure behavior defined.
- Workout timer interruption behavior defined.
- Notification permission denial flow checked.
- Accessibility pass for labels, dynamic type, contrast, and tap targets.
- Copy review for calm discipline tone.
- Subscription screen behavior clarified for MVP: enabled, disabled, placeholder, or TestFlight-only.

100% gate:

- Full MVP journey passes manually on at least two simulator/device sizes.
- Core MVP screens have stable loading/error states.
- Habit, workout, and reading completion cannot double-award XP.
- Daily progress survives app restart and session restoration.
- Calendar reflects complete, partial, missed, and forgiven days correctly.
- No critical user journey requires a developer or database reset.

## Milestone 2 - Private Alpha

Current estimate: 45-55%.

Goal:

RNF can be used by a small controlled group with monitoring, support, and rollback discipline.

Required product decisions:

- Alpha user count.
- Whether alpha uses real subscriptions or disables payments.
- Whether alpha permits placeholder/demo mode.
- What data can be reset during alpha.
- Support channel and expected response time.

Missing to reach 100%:

- Separate Supabase environments for development and alpha.
- Environment configuration runbook.
- Confirm RLS policies in a fresh Supabase project.
- Confirm reading-proof bucket policies in a fresh Supabase project.
- Seed/test data strategy.
- Crash reporting choice and setup.
- Minimal analytics event plan.
- User-safe logging review.
- Manual support runbook.
- Data deletion/reset process for alpha users.
- Privacy policy draft for alpha.
- Terms or alpha disclaimer.
- TestFlight internal testing setup.
- Known-issues doc before inviting users.

100% gate:

- Fresh environment can be created from migrations and runbook.
- Internal TestFlight build installs and launches.
- Alpha user can sign up, complete the loop, and return next day.
- Crash/diagnostic logs are available.
- Support and data-reset process are documented.
- Privacy policy is ready for alpha users.

## Milestone 3 - Public Beta

Current estimate: 35-45%.

Goal:

RNF can accept a wider TestFlight audience without fragile manual intervention.

Missing to reach 100%:

- App Store Connect app record.
- Bundle identifier and signing documented.
- TestFlight external testing checklist.
- App privacy nutrition labels drafted.
- App metadata draft: name, subtitle, description, keywords.
- Screenshot plan for required device sizes.
- Versioning policy.
- Release notes template.
- Public beta feedback process.
- Beta analytics dashboard.
- Performance baseline for launch, daily habit completion, calendar load, reading upload, workout completion.
- Image upload size and bandwidth limits.
- Recovery behavior for expired sessions.
- Regression checklist before every beta build.

100% gate:

- External TestFlight beta can be submitted.
- Beta build passes release checklist.
- App privacy metadata is internally reviewed.
- Basic analytics and crash visibility exist.
- Known issues are documented.
- No HIGH production-readiness risks remain.

## Milestone 4 - Production v1

Current estimate: 25-35%.

Goal:

RNF is ready for App Store release with real users, production data, and operational ownership.

Missing to reach 100%:

- Final privacy policy.
- Terms of use.
- Data deletion request process.
- Account deletion flow or documented support process.
- Production Supabase environment with backups.
- Migration rollback process tested.
- StoreKit 2 purchase, renewal, cancellation, and entitlement verification.
- Subscription receipt/server-validation decision.
- App Store review notes.
- App icons and launch assets final review.
- Accessibility acceptance pass.
- Security review for auth, RLS, storage, secrets, and logs.
- Incident response runbook.
- Monitoring dashboard.
- Support email or help channel.
- Release branch process tested.
- Production deployment checklist.

100% gate:

- App Store submission package is complete.
- Real subscription behavior is verified or intentionally deferred.
- Production environment is reproducible and backed up.
- Security checklist has no HIGH findings.
- Build, tests, and release checklist pass on the release branch.
- Team knows how to respond to auth, data, upload, and payment incidents.

## Milestone 5 - Scale And Team Readiness

Current estimate: 50-60%.

Goal:

RNF can support more developers without losing architecture, review quality, or release discipline.

Already in place:

- Professional branch naming guidance.
- GitHub PR template and issue templates.
- CODEOWNERS file.
- GitHub Actions workflow set.
- Builder/Verifier automation.
- Architecture and production readiness docs.

Missing to reach 100%:

- Confirm branch protection is actually enabled in GitHub.
- Confirm required CI checks match workflow names.
- Define team onboarding checklist.
- Define local setup checklist.
- Define code review checklist.
- Define release manager responsibilities.
- Define migration owner/reviewer rule.
- Add decision log for architecture/product decisions.
- Add changelog or release notes process.
- Add dependency update process for Swift packages.
- Add documentation owner rule.
- Add feature spec template.

100% gate:

- A new developer can clone, build, test, and understand workflow from docs.
- Pull requests are protected by CI and review.
- Architecture decisions are recorded.
- Releases are repeatable.
- Dependency and migration changes have explicit review rules.

## Milestone 6 - Apple Health

Current estimate: 10-15%.

Goal:

Add HealthKit only when it strengthens the iPhone core loop without bypassing RNF's progression rules.

Reference:

- `RNF_APPLE_HEALTH_INTEGRATION_SPEC.md`

Missing to reach 100%:

- Decide exact HealthKit data types.
- Write permission copy.
- Define whether HealthKit data is evidence, suggestions, or automatic completion.
- Define anti-cheat/validation rules.
- Add HealthKit entitlement and capability only in a dedicated task.
- Add HealthKit service boundary.
- Add privacy and App Store disclosure updates.
- Add tests/mocks for HealthKit unavailable, denied, partial permission, and revoked permission.
- Define manual fallback when HealthKit is off.

100% gate:

- HealthKit cannot auto-award XP without RNF validation rules.
- Permission denial does not break the app.
- Privacy copy is reviewed.
- App Store health-data disclosure is ready.
- iPhone MVP remains the source of truth.

## Milestone 7 - Apple Watch

Current estimate: 10-15%.

Goal:

Create a companion Watch experience only after the iPhone app is stable.

Reference:

- `RNF_APPLE_WATCH_SPEC.md`

Missing to reach 100%:

- Decide companion scope: habit check-in, workout timer, reminders, quick stats, or all of these.
- Define iPhone as source of truth.
- Define watch sync strategy.
- Define offline watch behavior.
- Add watchOS target only in a dedicated task.
- Add watch-specific ViewModels where needed.
- Add WatchConnectivity boundary.
- Add watch UI test/manual QA checklist.
- Add battery/performance checks.
- Add App Store metadata updates for watchOS.

100% gate:

- Watch cannot corrupt daily progress.
- Watch completion events are idempotent.
- iPhone and watch reconcile state deterministically.
- Watch app remains useful when offline and correct when resynced.
- App Store package includes watch assets and metadata.

## Cross-Milestone Gaps To Track

These can be missed because they do not look like app features.

### Product

- User journey acceptance criteria.
- Screen-by-screen empty/loading/error states.
- Product copy review.
- Accessibility review.
- Feedback/support process.

### Security And Privacy

- Privacy policy.
- Terms of use.
- Account/data deletion.
- Data export decision.
- RLS verification in fresh environment.
- Storage policy verification.
- Secret scanning and push protection enabled.

### Stability

- Offline/retry policy.
- Duplicate-safe writes.
- Session restoration.
- Image upload limits.
- Migration rollback testing.

### QA

- Manual regression checklist.
- Simulator/device matrix.
- UI smoke tests.
- Performance baseline.
- Beta known-issues list.

### Release

- Signing.
- App Store Connect.
- TestFlight.
- Versioning.
- Release notes.
- App privacy labels.
- Production environment checklist.

### Operations

- Monitoring.
- Crash reporting.
- Incident response.
- Support channel.
- Branch protection.
- Dependency update process.
- Team onboarding.

## Immediate Next Plan

Do not start a new product feature yet.

1. Finish Phase 16 architecture hardening.
2. Convert Milestone 1 missing items into a Phase 17 MVP acceptance task graph.
3. Run the MVP acceptance checklist manually and through tests where practical.
4. Convert Milestone 2 missing items into private-alpha setup tasks.
5. Only after private alpha is stable, plan public beta and production release tasks.

## Builder/Verifier Guidance

Builder:

- Use this document to understand milestone gates.
- Still select tasks only from `RNF/Docs/task_graph.md`.
- Do not implement milestone work unless it exists as the selected task.

Verifier:

- Use this document to detect incomplete milestone claims.
- Treat a milestone as incomplete if any required gate is missing.
- Treat accidental HealthKit/watchOS work before its milestone as out-of-scope.
