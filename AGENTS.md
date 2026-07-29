# RNF Agent Operating Contract

This repository uses **Moonbase KND Council** as its automation pipeline.

Each phase produces a **binary release** (TestFlight build) before proceeding to the next.

---

## Pipeline Tool

**Moonbase** (`moonbase mission`) executes the full KND Council pipeline per task:

```
Phase 1: Numbuh 1 (Analyst) — Requirements & ACs
Phase 2: Numbuh 2 (Architect) — Design & file plan
Phase 3: Numbuh 3 (Implementer) — Code & tests
Phase 4: Numbuh 4 (QA) — AC verification & risk gate
Phase 5: Numbuh 5 (Reviewer) — PR summary & review
+ Conditional: Numbuh 0 (Oversight), 274 (Security), 362 (DevOps)
```

---

## Execution Model

### Per-Task Execution

```bash
moonbase mission "P21-FIX-01: Replace fatalError in AppConfig with graceful Optional return"
```

Each task from `RNF/Docs/task_graph.md` is a single moonbase mission. The KND Council handles the full cycle — no separate Builder/Verifier loop needed.

### Per-Phase Binary Release

After all tasks in a phase are complete:

1. All tests pass (`xcodebuild test`)
2. Build succeeds (`xcodebuild archive`)
3. Tag the release (`git tag phase-XX-complete`)
4. Push to TestFlight (via Fastlane or manual archive)
5. Update `RNF/Docs/task_graph.md` phase header with release tag

Release naming: `v1.0-phase21`, `v1.0-phase22`, etc.

---

## Task Graph Usage

`RNF/Docs/task_graph.md` remains the source of truth for work ordering.

Every mission must:

1. Read the task graph
2. Identify dependency-free tasks
3. Execute exactly one task per mission
4. Mark the task `[x]` on completion
5. Respect dependency chains — never start a blocked task

If multiple tasks are dependency-free, pick the earliest task ID.

---

## Architecture Rules

Agents must:

- Follow existing SwiftUI + MVVM patterns
- Keep changes local to the selected task
- Reference the relevant spec in `RNF/Docs/specs/` for implementation guidance
- Avoid broad refactors unless the task explicitly requires it
- Run build + tests before marking complete

---

## Risk Gate (Phase 4 — Numbuh 4)

After implementation, QA classifies risk:

| Risk | Action |
|------|--------|
| **LOW** | Mark task complete, proceed to next |
| **MEDIUM** | Rework implementation (max 2 loops) |
| **HIGH** | Rework architecture |
| **CRITICAL** | Stop. Escalate to human. |

This replaces the old Verifier trust score system. The KND Council's built-in risk gate is more granular and doesn't require a separate agent.

---

## Phase Completion Checklist

Before tagging a phase release:

- [ ] All phase tasks marked `[x]` in task_graph.md
- [ ] `xcodebuild build` succeeds
- [ ] `xcodebuild test` passes (RNFTests target)
- [ ] No regressions in existing tests
- [ ] Git tag created: `phase-XX-complete`
- [ ] Binary archived for TestFlight
- [ ] CHANGELOG updated with phase summary

---

## Spec References

Each phase maps to spec documents in `RNF/Docs/specs/`:

| Phase | Spec |
|-------|------|
| 21 | SPEC_PRODUCTION_BLOCKERS.md + SPEC_UI_UX_FIXES.md |
| 22 | SPEC_ONBOARDING_REDESIGN.md + SPEC_EMOTIONAL_DESIGN.md |
| 23 | SPEC_MONETIZATION.md |
| 24 | SPEC_RETENTION_PSYCHOLOGY.md + SPEC_GROWTH_VIRALITY.md |
| 25 | SPEC_INTELLIGENCE_PERSONALIZATION.md |
| 26 | SPEC_APPLE_PLATFORM.md |
| 27 | SPEC_LIFECYCLE_ENDGAME.md |
| 28 | SPEC_PERSONAS_INCLUSIVITY.md |
| 29 | SPEC_INFRASTRUCTURE_DEVOPS.md |
| 30 | SPEC_COMPETITIVE_GAPS.md (Streak Survival & Day-1 Wins) |
| 31 | SPEC_COMPETITIVE_GAPS.md (Flexible Intensity & Forecast) |
| 32 | SPEC_COMPETITIVE_GAPS.md (Social Enhancement & League Urgency) |

Agents MUST read the relevant spec before implementing any task.

---

## Batch Execution

To process an entire phase:

```bash
# Run all dependency-free tasks in Phase 21 sequentially
moonbase mission "Execute all Phase 21 tasks from RNF/Docs/task_graph.md in dependency order"
```

Or individually:

```bash
moonbase mission "P21-FIX-01: Replace fatalError in AppConfig with graceful Optional return"
moonbase mission "P21-FIX-02: Update SupabaseService.init to handle nil URL gracefully"
# ... etc
```

---

## Stop Conditions

The pipeline stops when:

- Numbuh 4 reports CRITICAL risk
- Build fails after 2 rework attempts
- A task requires architectural changes not described in specs
- Human approval is needed (production configs, infrastructure, CI/CD)
- Scope expands beyond the single task boundary

---

## Conditional Specialists

Trigger automatically based on changes:

| Specialist | Triggers When |
|-----------|---------------|
| Numbuh 0 (Oversight) | >5 files changed or core logic modified |
| Numbuh 274 (Security) | Auth, input handling, or new dependencies changed |
| Numbuh 362 (DevOps) | CI/CD, deploy configs, or infra changed |
| Numbuh 86 (Decommission) | Old code removal needed |
| Numbuh 9 (Migration) | Database migrations or data model changes |

---

## Legacy

The previous Builder → Verifier → Trust Loop system has been retired. The `scripts/rnf_cycle.sh` automation script is deprecated. All automation now flows through Moonbase.
