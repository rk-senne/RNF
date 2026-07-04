# RNF Specification Index

**Generated:** 2026-07-03  
**Total Specs:** 12 documents | ~15,600 lines | Covers 90+ discrete improvements  
**Source:** Comprehensive code audit + product gap analysis + competitive research

---

## How to Use This Index

These specs are the implementation blueprint for everything identified in the [RNF Comprehensive Audit](../RNF_COMPREHENSIVE_AUDIT.md). They are ordered by priority — fix Phase 1 before moving to Phase 2.

Each spec is self-contained with: problem statements, solution designs, code-level implementation guidance, acceptance criteria, and dependency mapping. Engineers can implement directly from any spec without additional context.

### Execution via Moonbase

```bash
# Execute a single task
moonbase mission "P21-FIX-01: Replace fatalError in AppConfig with graceful Optional return"

# Execute all tasks in a phase
moonbase mission "Execute all Phase 21 tasks from RNF/Docs/task_graph.md in dependency order"
```

Each phase produces a **binary release** (TestFlight build) before the next phase begins. See [AGENTS.md](../../../AGENTS.md) for the full execution contract.

---

## Priority Phases

### 🔴 Phase 1: Ship Blockers (Week 1-2)
Must fix before ANY release — App Store rejection risks + production crashes.

| # | Spec | Key Items | Lines |
|---|------|-----------|-------|
| 1 | [SPEC_PRODUCTION_BLOCKERS.md](./SPEC_PRODUCTION_BLOCKERS.md) | SupabaseService crash, FocusCompletionHandler XP loss, Watch fixes, Account deletion, Sign in with Apple | 1,292 |
| 2 | [SPEC_UI_UX_FIXES.md](./SPEC_UI_UX_FIXES.md) | Navigation paths, LoginView↔SignUpView, error display, gesture conflicts | 984 |
| 3 | [SPEC_INFRASTRUCTURE_DEVOPS.md](./SPEC_INFRASTRUCTURE_DEVOPS.md) | CI secrets, release pipeline (critical for TestFlight) | 1,240 |

### 🟠 Phase 2: Core Experience (Week 3-5)
Makes the app feel complete and retain users past Day 1.

| # | Spec | Key Items | Lines |
|---|------|-----------|-------|
| 4 | [SPEC_ONBOARDING_REDESIGN.md](./SPEC_ONBOARDING_REDESIGN.md) | Try-before-commit, archetype quiz, first-session victory, progressive onboarding | 1,280 |
| 5 | [SPEC_EMOTIONAL_DESIGN.md](./SPEC_EMOTIONAL_DESIGN.md) | Welcome-back flow, graduated success, Life Happened pause, rest days | 1,249 |
| 6 | [SPEC_MONETIZATION.md](./SPEC_MONETIZATION.md) | Free vs Pro tier, 14-day trial, StoreKit 2, paywall design | 789 |

### 🟡 Phase 3: Retention & Growth (Week 6-9)
Turns a working app into a sticky, growing product.

| # | Spec | Key Items | Lines |
|---|------|-----------|-------|
| 7 | [SPEC_RETENTION_PSYCHOLOGY.md](./SPEC_RETENTION_PSYCHOLOGY.md) | Critical hit XP, endowed progress, social proof, Forge Tokens, leagues | 769 |
| 8 | [SPEC_GROWTH_VIRALITY.md](./SPEC_GROWTH_VIRALITY.md) | Shareable milestones, referrals, 1v1 challenges, buddy system, ASO, content moderation | 2,394 |
| 9 | [SPEC_INTELLIGENCE_PERSONALIZATION.md](./SPEC_INTELLIGENCE_PERSONALIZATION.md) | Adaptive notifications, dynamic difficulty, churn prediction, behavioral insights | 682 |

### 🟢 Phase 4: Platform & Depth (Week 10-14)
Premium differentiators and platform-native features.

| # | Spec | Key Items | Lines |
|---|------|-----------|-------|
| 10 | [SPEC_APPLE_PLATFORM.md](./SPEC_APPLE_PLATFORM.md) | App Intents, interactive widgets, HealthKit, Background Refresh, App Attest, Live Activities | 2,331 |
| 11 | [SPEC_LIFECYCLE_ENDGAME.md](./SPEC_LIFECYCLE_ENDGAME.md) | Post-90 chapters, prestige/rebirth, habit leveling, seasonal events, legacy system | 1,513 |
| 12 | [SPEC_PERSONAS_INCLUSIVITY.md](./SPEC_PERSONAS_INCLUSIVITY.md) | Alternative themes, ADHD mode, progressive commitment, cultural sensitivity | 884 |

---

## Cross-Cutting Concerns

These topics span multiple specs:

| Concern | Primary Spec | Also Referenced In |
|---------|-------------|-------------------|
| Offline resilience | Apple Platform (§3) | Production Blockers, Infrastructure |
| Streak protection | Retention Psychology (§5) | Emotional Design (§4, §5), Monetization (§6) |
| Forge Tokens economy | Retention Psychology (§4) | Monetization (§4), Growth (§2, §3), Lifecycle (§2) |
| Deep linking | Infrastructure (§5) | Growth (§2), Apple Platform (§6) |
| Feature gating by level | Onboarding (§5) | Retention, Lifecycle, Personas |
| Content moderation | Growth (§7) | Production Blockers (UGC safety) |
| Dynamic Type / Accessibility | UI/UX Fixes (§2) | Personas (§5) |
| Notification strategy | Intelligence (§1, §4) | Growth (§8), Emotional Design |
| Theme system | Personas (§1) | Emotional Design (§3), Lifecycle (§6) |

---

## Dependency Graph (Implementation Order)

```
SPEC_PRODUCTION_BLOCKERS ─────────┐
SPEC_UI_UX_FIXES ─────────────────┤
SPEC_INFRASTRUCTURE_DEVOPS ────────┤──▶ Private Alpha (TestFlight)
                                   │
SPEC_ONBOARDING_REDESIGN ──────────┤
SPEC_EMOTIONAL_DESIGN ─────────────┤
SPEC_MONETIZATION ─────────────────┤──▶ Public Beta
                                   │
SPEC_RETENTION_PSYCHOLOGY ─────────┤
SPEC_GROWTH_VIRALITY ──────────────┤
SPEC_INTELLIGENCE_PERSONALIZATION ─┤──▶ v1.0 Launch
                                   │
SPEC_APPLE_PLATFORM ───────────────┤
SPEC_LIFECYCLE_ENDGAME ────────────┤
SPEC_PERSONAS_INCLUSIVITY ─────────┘──▶ v1.1+ (Post-Launch)
```

---

## Key Metrics Targets (Across All Specs)

| Metric | Target | Measured By |
|--------|--------|-------------|
| Day 1 → Day 2 retention | ≥ 60% | Analytics |
| Day 7 retention | ≥ 40% | Analytics |
| Day 30 retention | ≥ 25% | Analytics |
| Trial → Paid conversion | 12-15% | StoreKit |
| App Store rating | ≥ 4.7 | App Store Connect |
| Crash-free sessions | ≥ 99.5% | Sentry |
| Viral coefficient | ≥ 0.3 | Referral tracking |
| Weekly active users (WAU) | Growing 10% MoM | Analytics |
| Time to first habit completion | < 3 minutes | Onboarding funnel |
| Average daily session count | ≥ 2 | Analytics |

---

## Document Totals

| Spec | Lines | Key Deliverables |
|------|-------|-----------------|
| SPEC_PRODUCTION_BLOCKERS | 1,292 | 7 critical fixes with code guidance |
| SPEC_ONBOARDING_REDESIGN | 1,280 | 7 onboarding moments, full user journey |
| SPEC_RETENTION_PSYCHOLOGY | 769 | 7 psychological mechanics, economy model |
| SPEC_EMOTIONAL_DESIGN | 1,249 | 7 emotional intelligence features |
| SPEC_MONETIZATION | 789 | Full business model, StoreKit 2, projections |
| SPEC_APPLE_PLATFORM | 2,331 | 11 Apple framework integrations |
| SPEC_GROWTH_VIRALITY | 2,394 | 8 growth systems, ASO, moderation |
| SPEC_INTELLIGENCE_PERSONALIZATION | 682 | 6 adaptive intelligence systems |
| SPEC_LIFECYCLE_ENDGAME | 1,513 | 7 endgame systems for power users |
| SPEC_PERSONAS_INCLUSIVITY | 884 | 7 inclusivity improvements, 5 personas |
| SPEC_INFRASTRUCTURE_DEVOPS | 1,240 | 12 DevOps improvements |
| SPEC_UI_UX_FIXES | 984 | 14 technical UI fixes |
| **TOTAL** | **~15,600** | **90+ discrete improvements** |

---

## Status Tracking

| Spec | Status | Started | Completed |
|------|--------|---------|-----------|
| SPEC_PRODUCTION_BLOCKERS | 📋 Specced | — | — |
| SPEC_UI_UX_FIXES | 📋 Specced | — | — |
| SPEC_INFRASTRUCTURE_DEVOPS | 📋 Specced | — | — |
| SPEC_ONBOARDING_REDESIGN | 📋 Specced | — | — |
| SPEC_EMOTIONAL_DESIGN | 📋 Specced | — | — |
| SPEC_MONETIZATION | 📋 Specced | — | — |
| SPEC_RETENTION_PSYCHOLOGY | 📋 Specced | — | — |
| SPEC_GROWTH_VIRALITY | 📋 Specced | — | — |
| SPEC_INTELLIGENCE_PERSONALIZATION | 📋 Specced | — | — |
| SPEC_APPLE_PLATFORM | 📋 Specced | — | — |
| SPEC_LIFECYCLE_ENDGAME | 📋 Specced | — | — |
| SPEC_PERSONAS_INCLUSIVITY | 📋 Specced | — | — |

Status legend: 📋 Specced | 🚧 In Progress | ✅ Complete | ⏸️ Deferred

---

## Related Documents

- [RNF_COMPREHENSIVE_AUDIT.md](../RNF_COMPREHENSIVE_AUDIT.md) — Original audit findings
- [task_graph.md](../task_graph.md) — Existing implementation task graph (374/377 complete)
- [RNF_PROJECT_OVERVIEW.md](../RNF_PROJECT_OVERVIEW.md) — Project overview and philosophy
- [RNF_FEATURE_ROADMAP.md](../RNF_FEATURE_ROADMAP.md) — Original feature roadmap
- [AGENTS.md](../../../AGENTS.md) — Builder/Verifier automation contract
