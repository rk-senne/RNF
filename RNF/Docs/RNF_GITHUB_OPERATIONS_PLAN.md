# RNF GitHub Operations Plan

This document defines the GitHub setup RNF should use as it moves from solo development toward a small team.

The goal is simple: protect `main`, keep `develop` healthy, make reviews predictable, and avoid process overhead before it pays for itself.

## Branch Model

Use professional branch names.

Primary branches:

```text
main
develop
```

Work branches:

```text
feature/<short-name>
fix/<short-name>
docs/<short-name>
infra/<short-name>
chore/<short-name>
release/<version>
hotfix/<short-name>
```

Rules:

- `main` is stable.
- `develop` is the integration branch.
- feature branches merge into `develop`.
- release branches are created from `develop` when preparing a release.
- hotfix branches are created from `main` only for urgent production fixes.

Avoid AI-labeled branch prefixes in public repo history. The repo should look like a normal startup engineering codebase.

## Pull Request Rules

Every non-trivial change should use a pull request.

PRs must state:

- summary
- scope
- task graph reference if applicable
- tests/builds run
- migration impact
- risk level

Small docs-only fixes can be merged with lighter review, but they should still be clear.

## Required GitHub Files

Set up now:

```text
.github/pull_request_template.md
.github/ISSUE_TEMPLATE/bug_report.yml
.github/ISSUE_TEMPLATE/feature_request.yml
.github/ISSUE_TEMPLATE/task.yml
.github/CODEOWNERS
.github/dependabot.yml
.github/workflows/ios-build.yml
.github/workflows/ios-tests.yml
.github/workflows/docs-check.yml
.github/workflows/migrations-check.yml
```

Defer until later:

```text
release-drafter.yml
TestFlight deployment workflow
App Store release workflow
strict coverage gates
strict SwiftLint gate
```

## Branch Protection

Configure this manually in GitHub settings after CI is merged and green.

### `main`

Recommended protections:

- require pull request before merge
- require status checks
- require `iOS Build`
- require `iOS Tests`
- require `Supabase Migration Check`
- require linear history
- block force pushes
- block direct pushes
- require conversation resolution

### `develop`

Recommended protections:

- require pull request before merge
- require status checks
- require `iOS Build`
- require `iOS Tests`
- require `Documentation Check`
- require `Supabase Migration Check`
- require conversation resolution

## Labels

Create these labels in GitHub when issue tracking begins.

Areas:

```text
area/auth
area/supabase
area/ui
area/watch
area/healthkit
area/workouts
area/reading
area/challenge
area/automation
area/docs
```

Types:

```text
type/bug
type/feature
type/chore
type/refactor
type/test
```

Risk:

```text
risk/low
risk/medium
risk/high
```

Status:

```text
status/blocked
status/ready
status/in-review
```

## Milestones

Recommended milestones:

```text
MVP Core Loop
Private Alpha
Public Beta
Production v1
Apple Health
Apple Watch
```

## GitHub Project Board

Use one project board when coordination becomes useful.

Columns:

```text
Backlog
Ready
In Progress
Verifier Review
Blocked
Done
```

This mirrors the Builder -> Verifier workflow.

## Security Settings

Enable in GitHub repository settings:

- secret scanning
- push protection
- Dependabot alerts
- Dependabot security updates

These matter because RNF uses Supabase and will eventually handle user-owned habit, challenge, workout, reading, and subscription data.

## Dependabot

Initial scope:

- GitHub Actions updates

Deferred:

- Swift package automation, until package update behavior is verified against RNF's Xcode project.

## Release Automation

Do not automate App Store or TestFlight releases yet.

Add release workflows only after:

- command-line builds are reliable
- tests are stable
- signing is documented
- release branches exist
- product versioning is clear

## Known Follow-Up

Create a cleanup branch:

```text
chore/remove-xcode-userdata
```

Purpose:

- remove tracked `RNF.xcodeproj/xcuserdata/`
- confirm `.gitignore` blocks future user-specific Xcode state
- then tighten `docs-check.yml` to reject tracked `xcuserdata`
