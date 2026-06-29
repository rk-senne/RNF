# RNF Feature Roadmap

This document defines the development phases for RNF.

The roadmap ensures features are built in the correct order and prevents feature creep.

Each phase must be completed before moving to the next.

---

# Phase 1 — MVP (Core Discipline Loop)

Goal:

Validate the 90-day discipline system and achieve strong retention.

Target metric:

Day 7 retention ≥ 40%

---

## Core Systems

Authentication  
User profile  
Daily logs  
Habit completion  
XP system  
Level system  
Stats system  
Streak system

---

## Core Screens

Splash  
Login / Sign Up  
Notification Setup  
90-Day Commitment  
Home (Daily Habits)  
Workouts  
Read  
Profile  
Subscription

---

## Core Features

Daily habit tracking  
Workout timer  
Reading proof upload  
Calendar tracking  
Forgiveness system  
XP rewards  
Level progression

---

## Backend Systems

Supabase Auth  
PostgreSQL database  
Daily log system  
Habit completion tracking  
Reading proof storage

---

## Completion Criteria

Users can:

• create account  
• start 90-day challenge  
• complete habits  
• gain XP  
• maintain streak  
• view progress calendar  

---

# Phase 2 — Engagement Expansion

Goal:

Increase retention and long-term engagement.

---

## New Systems

Quest generation system  
Skill tree system  
Evolution system  
Advanced stat progression

---

## New Features

Dynamic quests targeting weak stats  
Skill trees for specialization  
Evolution milestones  
Weekly habit unlock system

---

## New Screens

Quest screen  
Skill tree screen  
Habit selection screen

---

# Phase 3 — Advanced Progression

Goal:

Create deeper gameplay and identity systems.

---

## Systems

Boss challenges  
Achievement system  
Mastery paths  
Advanced titles

---

## Features

Challenge events  
Achievement badges  
Advanced character paths

---

# Phase 4 — Social Expansion

Goal:

Introduce community and competitive elements.

---

## Systems

Guilds  
Social challenges  
Leaderboards

---

## Features

Friend progress comparison  
Group habit challenges  
Community streak events

---

# Phase 15 — Launch Enhancements

Goal:

Polish UX, add resilience, and improve first-session conversion before public launch.

Depends on: Phase 14 completion.

---

## Haptic Feedback and Micro-Animations

Haptic success tap on habit completion  
XP gain animation with haptic pulse on level-up  
Streak milestone celebration animation

---

## iOS Widget

WidgetKit extension with shared data model  
Small widget: streak count + daily progress ring  
Medium widget: today's quest list with completion state  
Timeline refresh on habit completion and app foreground

---

## Data Export

JSON export of user progress  
CSV export for daily logs and habit completions  
Share sheet integration for exported files

---

## Onboarding Friction Reduction

Guest tryout mode: one day of habit tracking without account creation  
Account creation gate after first day with data migration to authenticated user

---

## Error UX

Toast/banner error component for transient failures  
Retry action on error banners  
Offline indicator banner when network unreachable

---

## Offline Handling

NetworkMonitor service using NWPathMonitor  
Local-first write queue for habit completions when offline  
Background sync flush on connectivity restore  
Idempotent deduplication on sync flush

---

## Session Restoration Robustness

Token expiry detection and silent refresh  
Graceful fallback state when Supabase unreachable during launch  
Cached last-known state display during session restoration

---

## Accessibility Audit

44pt minimum tap target verification across all screens  
VoiceOver labels and hints on all custom components  
Dynamic Type support verification at all accessibility sizes  
WCAG AA contrast ratio verification for all color combinations  
Reduce Motion support for all animations

---

## App Store Rating Prompt

SKStoreReviewController trigger at streak milestones (7-day, 30-day, 50 habits)  
90-day cooldown enforcement  
Never prompt during onboarding or after failures

---

## Theme Toggle

Theme preference model (light / dark / system) persisted in UserDefaults  
preferredColorScheme applied at app root  
Theme selection UI in profile settings

---

# Phase 5 — AI Expansion [DEFERRED]

Status: DEFERRED — not required for launch. Revisit post-launch when retention data justifies personalization investment.

Goal:

Use AI to personalize the system.

---

## Systems

AI quest generation  
Habit recommendations  
Behavior analysis

---

## Features

Adaptive quests  
AI discipline coach  
Smart habit suggestions

---

---

# Phase 6 — Apple Platform Expansion

Goal:

Extend RNF into Apple ecosystem surfaces only after the iPhone core loop is stable.

Reference specs:

- `RNF_APPLE_HEALTH_INTEGRATION_SPEC.md`
- `RNF_APPLE_WATCH_SPEC.md`

Priority order:

1. Complete iPhone MVP.
2. Stabilize auth, sync, daily logs, challenge lifecycle, workouts, and reading.
3. Add HealthKit integration if product validation supports it.
4. Add Apple Watch as a companion client.

Rules:

- Apple Watch is a companion client, not the source of truth.
- HealthKit data is evidence, not automatic XP.
- Neither integration may bypass RNF service, engine, idempotency, or privacy rules.


# Product Philosophy

RNF should evolve gradually.

Never introduce systems before the core loop is stable.

The priority order is:

Core discipline loop  
Engagement systems  
Advanced progression  
Social expansion  
AI assistance
