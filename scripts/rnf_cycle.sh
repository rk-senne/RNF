#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/Users/regosenne/Desktop/Dev/RNF"
STATE_DIR="$ROOT_DIR/.rnf"
LOG_DIR="$STATE_DIR/logs"
PROMPT_DIR="$STATE_DIR/prompts"
TRUST_FILE="$STATE_DIR/trust_score"
HIGH_COUNT_FILE="$STATE_DIR/high_count"
LAST_RISK_FILE="$STATE_DIR/last_risk"
LAST_FAILURE_FILE="$STATE_DIR/last_failure"
LOW_STREAK_FILE="$STATE_DIR/low_streak"
HANDOFF_FILE="$STATE_DIR/session_handoff"
ROLLOVER_COUNT_FILE="$STATE_DIR/rollover_count"
ACTIVE_TASK_FILE="$STATE_DIR/active_task"
LAST_VERIFIER_LOG_FILE="$STATE_DIR/last_verifier_log"

BUILDER_PROMPT="$ROOT_DIR/scripts/rnf_builder_prompt.txt"
VERIFIER_PROMPT="$ROOT_DIR/scripts/rnf_verifier_prompt.txt"
TASK_GRAPH="$ROOT_DIR/RNF/Docs/task_graph.md"
PRODUCTION_SPEC="$ROOT_DIR/RNF/Docs/RNF_PRODUCTION_READINESS_SPEC.md"

CODEX_BIN="${CODEX_BIN:-/Users/regosenne/.npm-global/bin/codex}"
CODEX_MODEL="${CODEX_MODEL:-}"
RNF_MAX_CYCLES="${RNF_MAX_CYCLES:-1}"
RNF_RUN_UNTIL_BLOCKED="${RNF_RUN_UNTIL_BLOCKED:-0}"
RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES="${RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES:-10}"
TRUST_MAX="${TRUST_MAX:-100}"
HIGH_LIMIT="${HIGH_LIMIT:-3}"
LOW_STREAK_PAUSE_LIMIT="${LOW_STREAK_PAUSE_LIMIT:-3}"
RNF_CONTEXT_RETRY_LIMIT="${RNF_CONTEXT_RETRY_LIMIT:-1}"
RNF_FIX_UNTIL_LOW="${RNF_FIX_UNTIL_LOW:-1}"
RNF_MAX_FIX_ATTEMPTS="${RNF_MAX_FIX_ATTEMPTS:-3}"

mkdir -p "$LOG_DIR"
mkdir -p "$PROMPT_DIR"

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 2
  fi
}

require_int() {
  local name="$1"
  local value="$2"
  if ! [[ "$value" =~ ^[0-9]+$ ]] || [[ "$value" -lt 1 ]]; then
    echo "$name must be a positive integer" >&2
    exit 2
  fi
}

require_bool() {
  local name="$1"
  local value="$2"
  if [[ "$value" != "0" && "$value" != "1" ]]; then
    echo "$name must be 0 or 1" >&2
    exit 2
  fi
}

read_number() {
  local file="$1"
  local fallback="$2"

  if [[ -f "$file" ]]; then
    local value
    value="$(tr -d '[:space:]' < "$file")"
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      echo "$value"
      return
    fi
  fi

  echo "$fallback"
}

write_number() {
  printf '%s\n' "$2" > "$1"
}

read_text() {
  local file="$1"
  local fallback="$2"

  if [[ -f "$file" ]]; then
    local value
    value="$(sed -n '1p' "$file")"
    if [[ -n "$value" ]]; then
      echo "$value"
      return
    fi
  fi

  echo "$fallback"
}

write_text() {
  printf '%s\n' "$2" > "$1"
}

codex_exec() {
  local prompt_file="$1"
  local output_file="$2"

  if [[ -n "$CODEX_MODEL" ]]; then
    "$CODEX_BIN" exec --cd "$ROOT_DIR" --model "$CODEX_MODEL" --sandbox workspace-write < "$prompt_file" | tee "$output_file"
  else
    "$CODEX_BIN" exec --cd "$ROOT_DIR" --sandbox workspace-write < "$prompt_file" | tee "$output_file"
  fi
}

current_task() {
  local task
  task="$(grep -E '^- \[ \] ' "$TASK_GRAPH" | sed -n '1p' || true)"

  if [[ -n "$task" ]]; then
    echo "$task"
    return
  fi

  echo "none"
}

dirty_files() {
  git -C "$ROOT_DIR" status --short \
    | awk '{print $2}' \
    | sed '/^$/d' \
    | sort \
    | paste -sd ', ' -
}

latest_log() {
  local pattern="$1"
  find "$LOG_DIR" -type f -name "$pattern" -print0 2>/dev/null \
    | xargs -0 ls -t 2>/dev/null \
    | sed -n '1p' || true
}

last_risk_from_logs() {
  local log
  log="$(latest_log '*_verifier.log')"

  if [[ -n "$log" ]]; then
    local risk
    risk="$(extract_risk "$log")"
    if [[ -n "$risk" ]]; then
      echo "$risk"
      return
    fi
  fi

  read_text "$LAST_RISK_FILE" "NONE"
}

failure_reason_from_file() {
  local output_file="$1"

  if grep -Eiq 'no (next |dependency-free )?task|no task is dependency-free|no dependency-free task|no available task|nothing to implement' "$output_file"; then
    echo "no next task is available"
    return
  fi

  if grep -Eiq 'build (failed|failure)|failed build|build did not succeed' "$output_file"; then
    echo "build fails"
    return
  fi

  if grep -Eiq 'verifier failed|risk output invalid|invalid risk' "$output_file"; then
    echo "Verifier fails"
    return
  fi

  if grep -Eiq 'builder failed' "$output_file"; then
    echo "Builder fails"
    return
  fi

  echo ""
}

last_failure_from_logs() {
  local log

  log="$(latest_log '*_builder.log')"
  if [[ -n "$log" ]]; then
    local reason
    reason="$(failure_reason_from_file "$log")"
    if [[ -n "$reason" ]]; then
      echo "$reason"
      return
    fi
  fi

  log="$(latest_log '*_verifier.log')"
  if [[ -n "$log" ]]; then
    local risk
    risk="$(extract_risk "$log")"
    case "$risk" in
      MEDIUM)
        echo "Verifier returns MEDIUM"
        return
        ;;
      HIGH)
        echo "Verifier returns HIGH"
        return
        ;;
    esac

    local reason
    reason="$(failure_reason_from_file "$log")"
    if [[ -n "$reason" ]]; then
      echo "$reason"
      return
    fi
  fi

  read_text "$LAST_FAILURE_FILE" "none"
}

prompt_with_context() {
  local base_prompt_file="$1"
  local last_risk="$2"
  local last_failure="$3"
  local task="$4"
  local fix_attempt="$5"
  local max_fix_attempts="$6"
  local pre_existing_dirty="$7"
  local verifier_log="$8"

  printf '%s\n\nContext:\n- Last risk: %s\n- Last failure: %s\n- Current task: %s\n- Fix attempt: %s of %s\n- Pre-existing dirty files before this cycle: %s\n- Last verifier log: %s\n- Production spec: %s\n\nSystem loop instructions:\n- Each Builder and Verifier execution is a fresh Codex session. Continue from this context, not from chat history.\n- If Last risk is MEDIUM or HIGH, Builder must fix only the verifier findings for the Current task.\n- Verifier must review the Builder task change and ignore files listed as pre-existing dirty files unless the current Builder changed them for this task.\n- Continue correction until Verifier returns Risk Level: LOW or the system safety cap stops the loop.\n' \
    "$(cat "$base_prompt_file")" \
    "$last_risk" \
    "$last_failure" \
    "$task" \
    "$fix_attempt" \
    "$max_fix_attempts" \
    "${pre_existing_dirty:-none}" \
    "${verifier_log:-none}" \
    "$PRODUCTION_SPEC"
}

write_prompt_file() {
  local path="$1"
  local prompt_text="$2"

  printf '%s\n' "$prompt_text" > "$path"
}

context_limit_reason() {
  local output_file="$1"

  if [[ ! -f "$output_file" ]]; then
    echo ""
    return
  fi

  if grep -Eiq 'context (window|length|limit|full)|maximum context|token limit|too many tokens|prompt is too long|conversation is too long|chat is full' "$output_file"; then
    echo "context limit reached"
    return
  fi

  echo ""
}

run_agent() {
  local role="$1"
  local prompt_file="$2"
  local output_file="$3"
  local attempts=0
  local max_attempts="$((RNF_CONTEXT_RETRY_LIMIT + 1))"

  while [[ "$attempts" -lt "$max_attempts" ]]; do
    attempts="$((attempts + 1))"

    if [[ "$attempts" -gt 1 ]]; then
      echo "$role context limit detected. Starting a fresh Codex session from persisted handoff context."
      write_number "$ROLLOVER_COUNT_FILE" "$(( $(read_number "$ROLLOVER_COUNT_FILE" 0) + 1 ))"
    fi

    if codex_exec "$prompt_file" "$output_file"; then
      return 0
    fi

    local context_reason
    context_reason="$(context_limit_reason "$output_file")"
    if [[ "$context_reason" != "context limit reached" ]]; then
      return 1
    fi
  done

  return 1
}

write_handoff() {
  local cycle_number="$1"
  local task="$2"
  local last_risk="$3"
  local last_failure="$4"
  local trust_value="$5"
  local low_streak_value="$6"
  local fix_attempt="$7"
  local pre_existing_dirty="$8"

  {
    echo "RNF automation handoff"
    echo "Root: $ROOT_DIR"
    echo "Cycle: $cycle_number"
    echo "Current task: $task"
    echo "Last risk: $last_risk"
    echo "Last failure: $last_failure"
    echo "Trust score: $trust_value"
    echo "LOW-risk streak: $low_streak_value"
    echo "Fix attempt: $fix_attempt of $RNF_MAX_FIX_ATTEMPTS"
    echo "Pre-existing dirty files: ${pre_existing_dirty:-none}"
    echo "Task graph: $TASK_GRAPH"
    echo "Production spec: $PRODUCTION_SPEC"
    echo "Instruction: start a fresh Builder or Verifier session using the generated prompt files in $PROMPT_DIR, then continue until Verifier returns LOW or a safety cap stops the loop."
  } > "$HANDOFF_FILE"
}

extract_risk() {
  local output_file="$1"
  local risk_lines
  risk_lines="$(grep -E '^Risk Level: (LOW|MEDIUM|HIGH)$' "$output_file" || true)"

  if [[ "$(printf '%s\n' "$risk_lines" | sed '/^$/d' | wc -l | tr -d ' ')" != "1" ]]; then
    echo "MEDIUM"
    return
  fi

  printf '%s\n' "$risk_lines" | awk '{print $3}'
}

builder_stop_reason() {
  local output_file="$1"
  failure_reason_from_file "$output_file"
}

cycle_summary() {
  local cycle_number="$1"
  local risk="$2"
  local trust_value="$3"
  local stop_reason="$4"

  echo "Cycle: $cycle_number"
  echo "Verifier risk: $risk"
  echo "Trust score: $trust_value"
  if [[ -n "$stop_reason" ]]; then
    echo "Reason for stopping: $stop_reason"
  else
    echo "Reason for stopping: none"
  fi
}

require_file "$BUILDER_PROMPT"
require_file "$VERIFIER_PROMPT"
require_file "$TASK_GRAPH"
require_file "$PRODUCTION_SPEC"
require_file "$CODEX_BIN"

require_int "RNF_MAX_CYCLES" "$RNF_MAX_CYCLES"
require_bool "RNF_RUN_UNTIL_BLOCKED" "$RNF_RUN_UNTIL_BLOCKED"
require_int "RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES" "$RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES"
require_int "TRUST_MAX" "$TRUST_MAX"
require_int "HIGH_LIMIT" "$HIGH_LIMIT"
require_int "LOW_STREAK_PAUSE_LIMIT" "$LOW_STREAK_PAUSE_LIMIT"
require_int "RNF_CONTEXT_RETRY_LIMIT" "$RNF_CONTEXT_RETRY_LIMIT"
require_bool "RNF_FIX_UNTIL_LOW" "$RNF_FIX_UNTIL_LOW"
require_int "RNF_MAX_FIX_ATTEMPTS" "$RNF_MAX_FIX_ATTEMPTS"

trust="$(read_number "$TRUST_FILE" 0)"
high_count="$(read_number "$HIGH_COUNT_FILE" 0)"
low_streak="$(read_number "$LOW_STREAK_FILE" 0)"
rollover_count="$(read_number "$ROLLOVER_COUNT_FILE" 0)"

write_number "$TRUST_FILE" "$trust"
write_number "$HIGH_COUNT_FILE" "$high_count"
write_number "$LOW_STREAK_FILE" "$low_streak"
write_number "$ROLLOVER_COUNT_FILE" "$rollover_count"
write_text "$LAST_RISK_FILE" "$(last_risk_from_logs)"
write_text "$LAST_FAILURE_FILE" "$(last_failure_from_logs)"

cycle=1
fix_attempt=1
active_task="$(read_text "$ACTIVE_TASK_FILE" "")"
pre_existing_dirty="$(dirty_files)"

while :; do
  if [[ "$RNF_RUN_UNTIL_BLOCKED" != "1" && "$cycle" -gt "$RNF_MAX_CYCLES" ]]; then
    break
  fi

  if [[ "$RNF_RUN_UNTIL_BLOCKED" == "1" && "$cycle" -gt "$RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES" ]]; then
    echo "Completed $RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES run-until-blocked cycle(s). Final trust score: $(read_number "$TRUST_FILE" 0)"
    echo "Reason for stopping: RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES reached"
    exit 0
  fi

  stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
  builder_log="$LOG_DIR/${stamp}_cycle_${cycle}_builder.log"
  verifier_log="$LOG_DIR/${stamp}_cycle_${cycle}_verifier.log"
  if [[ -n "$active_task" ]]; then
    current_task="$active_task"
  else
    current_task="$(current_task)"
    write_text "$ACTIVE_TASK_FILE" "$current_task"
    active_task="$current_task"
  fi
  last_risk="$(last_risk_from_logs)"
  last_failure="$(last_failure_from_logs)"
  last_verifier_log="$(read_text "$LAST_VERIFIER_LOG_FILE" "none")"
  builder_prompt="$(prompt_with_context "$BUILDER_PROMPT" "$last_risk" "$last_failure" "$current_task" "$fix_attempt" "$RNF_MAX_FIX_ATTEMPTS" "$pre_existing_dirty" "$last_verifier_log")"
  verifier_prompt="$(prompt_with_context "$VERIFIER_PROMPT" "$last_risk" "$last_failure" "$current_task" "$fix_attempt" "$RNF_MAX_FIX_ATTEMPTS" "$pre_existing_dirty" "$last_verifier_log")"
  builder_prompt_file="$PROMPT_DIR/${stamp}_cycle_${cycle}_builder_prompt.txt"
  verifier_prompt_file="$PROMPT_DIR/${stamp}_cycle_${cycle}_verifier_prompt.txt"

  write_handoff "$cycle" "$current_task" "$last_risk" "$last_failure" "$trust" "$low_streak" "$fix_attempt" "$pre_existing_dirty"
  write_prompt_file "$builder_prompt_file" "$builder_prompt"
  write_prompt_file "$verifier_prompt_file" "$verifier_prompt"

  if [[ "$RNF_RUN_UNTIL_BLOCKED" == "1" ]]; then
    echo "RNF cycle $cycle/$RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES (run until blocked)"
  else
    echo "RNF cycle $cycle/$RNF_MAX_CYCLES"
  fi
  echo "Trust score: $trust"
  echo "High-risk count: $high_count"
  echo "LOW-risk streak: $low_streak"
  echo "Session rollover count: $(read_number "$ROLLOVER_COUNT_FILE" 0)"
  echo "Fix attempt: $fix_attempt/$RNF_MAX_FIX_ATTEMPTS"
  echo "Decision context:"
  echo "- Last risk: $last_risk"
  echo "- Last failure: $last_failure"
  echo "- Current task: $current_task"
  echo "- Pre-existing dirty files: ${pre_existing_dirty:-none}"
  echo "- Builder prompt: $builder_prompt_file"
  echo "- Verifier prompt: $verifier_prompt_file"
  echo "Chain reaction: Builder -> Verifier -> LOW advances to next task; MEDIUM/HIGH returns to Builder for the same task."

  if ! run_agent "Builder" "$builder_prompt_file" "$builder_log"; then
    echo "Builder failed. Stopping and resetting trust."
    write_number "$TRUST_FILE" 0
    context_reason="$(context_limit_reason "$builder_log")"
    if [[ "$context_reason" == "context limit reached" ]]; then
      write_text "$LAST_FAILURE_FILE" "Builder context limit reached"
      echo "Builder context limit reached after retry limit."
      cycle_summary "$cycle" "N/A" "$(read_number "$TRUST_FILE" 0)" "Builder context limit reached"
    else
      write_text "$LAST_FAILURE_FILE" "Builder fails"
      cycle_summary "$cycle" "N/A" "$(read_number "$TRUST_FILE" 0)" "Builder fails"
    fi
    echo "Builder log: $builder_log"
    exit 1
  fi

  stop_reason="$(builder_stop_reason "$builder_log")"
  if [[ -n "$stop_reason" ]]; then
    echo "Builder reported stop condition: $stop_reason"
    write_text "$LAST_FAILURE_FILE" "$stop_reason"
    echo "Builder log: $builder_log"
    cycle_summary "$cycle" "N/A" "$trust" "$stop_reason"
    exit 0
  fi

  if ! run_agent "Verifier" "$verifier_prompt_file" "$verifier_log"; then
    echo "Verifier failed. Stopping and resetting trust."
    write_number "$TRUST_FILE" 0
    context_reason="$(context_limit_reason "$verifier_log")"
    if [[ "$context_reason" == "context limit reached" ]]; then
      write_text "$LAST_FAILURE_FILE" "Verifier context limit reached"
      echo "Verifier context limit reached after retry limit."
      cycle_summary "$cycle" "N/A" "$(read_number "$TRUST_FILE" 0)" "Verifier context limit reached"
    else
      write_text "$LAST_FAILURE_FILE" "Verifier fails"
      cycle_summary "$cycle" "N/A" "$(read_number "$TRUST_FILE" 0)" "Verifier fails"
    fi
    echo "Verifier log: $verifier_log"
    exit 1
  fi

  risk="$(extract_risk "$verifier_log")"
  write_text "$LAST_RISK_FILE" "$risk"
  write_text "$LAST_VERIFIER_LOG_FILE" "$verifier_log"
  echo "Verifier risk: $risk"

  case "$risk" in
    LOW)
      high_count=0
      write_number "$HIGH_COUNT_FILE" "$high_count"
      low_streak="$((low_streak + 1))"
      write_number "$LOW_STREAK_FILE" "$low_streak"

      if [[ "$trust" -lt "$TRUST_MAX" ]]; then
        trust="$((trust + 1))"
      fi

      write_number "$TRUST_FILE" "$trust"
      write_text "$LAST_FAILURE_FILE" "none"
      write_text "$ACTIVE_TASK_FILE" ""
      write_text "$LAST_VERIFIER_LOG_FILE" ""
      active_task=""
      fix_attempt=1
      echo "Trust score updated: $trust"
      echo "LOW-risk streak updated: $low_streak"
      echo "Chain reaction: Verifier returned LOW. Current task accepted; next cycle will select the next dependency-free task."
      cycle_summary "$cycle" "$risk" "$trust" ""

      if [[ "$low_streak" -ge "$LOW_STREAK_PAUSE_LIMIT" ]]; then
        echo "LOW streak pause limit reached. Pausing for human verification."
        cycle_summary "$cycle" "$risk" "$trust" "LOW streak pause limit reached"
        exit 0
      fi
      ;;

    MEDIUM)
      echo "MEDIUM risk. Stopping with trust score preserved."
      low_streak=0
      write_number "$LOW_STREAK_FILE" "$low_streak"
      write_text "$LAST_FAILURE_FILE" "Verifier returns MEDIUM"
      echo "Verifier log: $verifier_log"
      cycle_summary "$cycle" "$risk" "$trust" "Verifier returns MEDIUM"
      if [[ "$RNF_FIX_UNTIL_LOW" == "1" && "$fix_attempt" -lt "$RNF_MAX_FIX_ATTEMPTS" ]]; then
        fix_attempt="$((fix_attempt + 1))"
        echo "Chain reaction: Verifier returned MEDIUM. Starting a fresh Builder session for the same task."
        cycle="$((cycle + 1))"
        continue
      fi
      echo "Correction safety cap reached or disabled. Pausing for human verification."
      exit 0
      ;;

    HIGH)
      high_count="$((high_count + 1))"
      low_streak=0
      write_number "$HIGH_COUNT_FILE" "$high_count"
      write_number "$LOW_STREAK_FILE" "$low_streak"
      write_number "$TRUST_FILE" 0
      write_text "$LAST_FAILURE_FILE" "Verifier returns HIGH"

      echo "HIGH risk. Trust reset."
      echo "High-risk count: $high_count"
      echo "Verifier log: $verifier_log"

      if [[ "$high_count" -ge "$HIGH_LIMIT" ]]; then
        echo "High-risk limit reached."
      fi

      cycle_summary "$cycle" "$risk" "$(read_number "$TRUST_FILE" 0)" "Verifier returns HIGH"
      if [[ "$RNF_FIX_UNTIL_LOW" == "1" && "$fix_attempt" -lt "$RNF_MAX_FIX_ATTEMPTS" ]]; then
        fix_attempt="$((fix_attempt + 1))"
        echo "Chain reaction: Verifier returned HIGH. Starting a fresh Builder session for the same task."
        cycle="$((cycle + 1))"
        continue
      fi
      echo "Correction safety cap reached. Pausing for human verification."
      exit 1
      ;;

    *)
      echo "Invalid risk value. Stopping with trust score preserved."
      write_text "$LAST_FAILURE_FILE" "Verifier risk output invalid"
      echo "Verifier log: $verifier_log"
      cycle_summary "$cycle" "$risk" "$trust" "Verifier risk output invalid"
      exit 1
      ;;
  esac

  cycle="$((cycle + 1))"
done

echo "Completed $RNF_MAX_CYCLES cycle(s). Final trust score: $(read_number "$TRUST_FILE" 0)"
echo "Reason for stopping: RNF_MAX_CYCLES reached"
