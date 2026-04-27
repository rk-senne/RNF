# RNF Agent Operating Contract

This repository uses a controlled automation loop:

Builder -> Verifier -> Trust Loop

The purpose of this contract is to allow Codex to work with limited autonomy while preserving project architecture, task ordering, and review discipline.

## Roles

### Builder

The Builder implements exactly one task per cycle.

Responsibilities:

- Read `AGENTS.md`, `RNF/Docs/task_graph.md`, and relevant RNF documentation before editing.
- Select the next dependency-free task from `RNF/Docs/task_graph.md`.
- Implement only that task.
- Preserve the existing SwiftUI architecture and local coding patterns.
- Update `RNF/Docs/task_graph.md` only to reflect the status of the single completed task.
- Run the project build.
- Stop immediately if dependencies are unclear, the build fails, or the task requires architectural changes not already described by the task graph.

The Builder must not:

- Implement more than one task in a cycle.
- Start work on a blocked task.
- Change unrelated app behavior.
- Refactor architecture unless the selected task explicitly requires it.
- Invent tasks outside `RNF/Docs/task_graph.md`.

### Verifier

The Verifier reviews only the most recent Builder change.

Responsibilities:

- Inspect the last change set only.
- Check correctness against the selected task.
- Check adherence to existing architecture.
- Check that `RNF/Docs/task_graph.md` was updated consistently.
- Check that the build result is acceptable.
- Output exactly one risk line:

```text
Risk Level: LOW
```

Allowed risk values are `LOW`, `MEDIUM`, and `HIGH`.

The Verifier must not:

- Implement app features.
- Review unrelated historical code.
- Rewrite the Builder change.
- Approve architecture drift.

### System Agent

The System agent owns the automation layer and trust loop.

Responsibilities:

- Run Builder.
- Run Verifier.
- Capture Builder and Verifier output.
- Parse the Verifier risk level deterministically.
- Maintain the trust score.
- Stop the loop when safety conditions require it.

The System agent must not:

- Modify RNF app code.
- Modify `RNF/Docs/task_graph.md`.
- Override Verifier risk decisions.
- Continue after a stop condition.

## Required Task Graph Usage

`RNF/Docs/task_graph.md` is the source of truth for work ordering.

Every Builder cycle must:

1. Read the task graph.
2. Identify tasks whose dependencies are complete.
3. Select exactly one dependency-free task.
4. Implement only that selected task.
5. Mark only that task according to the graph's existing status format.

If no dependency-free task exists, the Builder must stop without editing app code.

## Architecture Rules

The RNF architecture must remain stable.

Agents must:

- Follow existing SwiftUI patterns.
- Keep changes local to the selected task.
- Avoid introducing new architectural layers without explicit task graph direction.
- Avoid broad refactors.
- Avoid replacing established project conventions.

Any architecture drift is at least `MEDIUM` risk. Architecture drift that changes core data flow, navigation, persistence, or shared app contracts is `HIGH` risk.

## Stop Conditions

The automation loop must stop when any of these conditions occur:

- Verifier reports `HIGH` risk.
- Verifier reports `MEDIUM` risk.
- Dependencies are unclear.
- Builder cannot identify exactly one dependency-free task.
- Builder reports or causes a build failure.
- Builder or Verifier exits with a non-zero status.
- Verifier output does not contain exactly one valid `Risk Level: LOW|MEDIUM|HIGH` line.

Trust handling:

- `LOW`: increment trust score and continue if another cycle is allowed.
- `MEDIUM`: stop and preserve trust score.
- `HIGH`: stop and reset trust score to `0`.

## Determinism

Agents must prefer explicit repository state over inference.

The loop must be repeatable:

- One task per Builder run.
- One Verifier review per Builder run.
- One risk decision per cycle.
- One trust score update per cycle.
