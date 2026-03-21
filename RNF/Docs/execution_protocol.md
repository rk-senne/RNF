# RNF Execution Protocol

This protocol defines how agents work together to build the system.

--------------------------------

ROLES

Builder Agent:
- Implements tasks

Verifier Agent:
- Reviews implementation

Human (You):
- Final decision authority

--------------------------------

LOOP

1. Builder selects NEXT dependency-free task
2. Builder implements the task
3. Builder marks task complete
4. Verifier reviews implementation
5. Human decides:
   - APPROVE → continue
   - FIX → Builder patches
   - REJECT → redo task

--------------------------------

RULES

- Only ONE task per cycle
- No parallel execution
- No skipping dependencies
- No rewriting task_graph.md
- Verifier cannot modify code
- Builder cannot redesign architecture

--------------------------------

FAIL CONDITIONS

Stop execution if:

- Build fails
- Verifier reports HIGH risk
- Task dependencies are unclear

--------------------------------

SUCCESS CONDITIONS

- Task implemented correctly
- Build succeeds
- Verifier reports LOW or MEDIUM risk

--------------------------------

GOAL

Create a deterministic, step-by-step system for building RNF without chaos or rework.
