#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/Users/regosenne/Desktop/Dev/RNF"
STATE_DIR="$ROOT_DIR/.rnf"
LOG_DIR="$STATE_DIR/logs"
TRUST_FILE="$STATE_DIR/trust_score"
HIGH_COUNT_FILE="$STATE_DIR/high_count"

BUILDER_PROMPT="$ROOT_DIR/scripts/rnf_builder_prompt.txt"
VERIFIER_PROMPT="$ROOT_DIR/scripts/rnf_verifier_prompt.txt"
TASK_GRAPH="$ROOT_DIR/RNF/Docs/task_graph.md"

CODEX_BIN="${CODEX_BIN:-/Users/regosenne/.npm-global/bin/codex}"
CODEX_MODEL="${CODEX_MODEL:-}"
RNF_MAX_CYCLES="${RNF_MAX_CYCLES:-1}"
RNF_RUN_UNTIL_BLOCKED="${RNF_RUN_UNTIL_BLOCKED:-0}"
RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES="${RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES:-10}"
TRUST_MAX="${TRUST_MAX:-100}"
HIGH_LIMIT="${HIGH_LIMIT:-3}"

mkdir -p "$LOG_DIR"

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

codex_exec() {
  local prompt_file="$1"
  local output_file="$2"

  if [[ -n "$CODEX_MODEL" ]]; then
    "$CODEX_BIN" exec --cd "$ROOT_DIR" --model "$CODEX_MODEL" --sandbox workspace-write < "$prompt_file" | tee "$output_file"
  else
    "$CODEX_BIN" exec --cd "$ROOT_DIR" --sandbox workspace-write < "$prompt_file" | tee "$output_file"
  fi
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

  if grep -Eiq 'no (next |dependency-free )?task|no task is dependency-free|no dependency-free task|no available task|nothing to implement' "$output_file"; then
    echo "no next task is available"
    return
  fi

  if grep -Eiq 'build (failed|failure)|failed build|build did not succeed' "$output_file"; then
    echo "build fails"
    return
  fi

  echo ""
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
require_file "$CODEX_BIN"

require_int "RNF_MAX_CYCLES" "$RNF_MAX_CYCLES"
require_bool "RNF_RUN_UNTIL_BLOCKED" "$RNF_RUN_UNTIL_BLOCKED"
require_int "RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES" "$RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES"
require_int "TRUST_MAX" "$TRUST_MAX"
require_int "HIGH_LIMIT" "$HIGH_LIMIT"

trust="$(read_number "$TRUST_FILE" 0)"
high_count="$(read_number "$HIGH_COUNT_FILE" 0)"

write_number "$TRUST_FILE" "$trust"
write_number "$HIGH_COUNT_FILE" "$high_count"

cycle=1

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

  if [[ "$RNF_RUN_UNTIL_BLOCKED" == "1" ]]; then
    echo "RNF cycle $cycle/$RNF_RUN_UNTIL_BLOCKED_MAX_CYCLES (run until blocked)"
  else
    echo "RNF cycle $cycle/$RNF_MAX_CYCLES"
  fi
  echo "Trust score: $trust"
  echo "High-risk count: $high_count"

  if ! codex_exec "$BUILDER_PROMPT" "$builder_log"; then
    echo "Builder failed. Stopping and resetting trust."
    write_number "$TRUST_FILE" 0
    echo "Builder log: $builder_log"
    cycle_summary "$cycle" "N/A" "$(read_number "$TRUST_FILE" 0)" "Builder fails"
    exit 1
  fi

  stop_reason="$(builder_stop_reason "$builder_log")"
  if [[ -n "$stop_reason" ]]; then
    echo "Builder reported stop condition: $stop_reason"
    echo "Builder log: $builder_log"
    cycle_summary "$cycle" "N/A" "$trust" "$stop_reason"
    exit 0
  fi

  if ! codex_exec "$VERIFIER_PROMPT" "$verifier_log"; then
    echo "Verifier failed. Stopping and resetting trust."
    write_number "$TRUST_FILE" 0
    echo "Verifier log: $verifier_log"
    cycle_summary "$cycle" "N/A" "$(read_number "$TRUST_FILE" 0)" "Verifier fails"
    exit 1
  fi

  risk="$(extract_risk "$verifier_log")"
  echo "Verifier risk: $risk"

  case "$risk" in
    LOW)
      high_count=0
      write_number "$HIGH_COUNT_FILE" "$high_count"

      if [[ "$trust" -lt "$TRUST_MAX" ]]; then
        trust="$((trust + 1))"
      fi

      write_number "$TRUST_FILE" "$trust"
      echo "Trust score updated: $trust"
      cycle_summary "$cycle" "$risk" "$trust" ""
      ;;

    MEDIUM)
      echo "MEDIUM risk. Stopping with trust score preserved."
      echo "Verifier log: $verifier_log"
      cycle_summary "$cycle" "$risk" "$trust" "Verifier returns MEDIUM"
      exit 0
      ;;

    HIGH)
      high_count="$((high_count + 1))"
      write_number "$HIGH_COUNT_FILE" "$high_count"
      write_number "$TRUST_FILE" 0

      echo "HIGH risk. Trust reset."
      echo "High-risk count: $high_count"
      echo "Verifier log: $verifier_log"

      if [[ "$high_count" -ge "$HIGH_LIMIT" ]]; then
        echo "High-risk limit reached. Stopping hard."
      fi

      cycle_summary "$cycle" "$risk" "$(read_number "$TRUST_FILE" 0)" "Verifier returns HIGH"
      exit 1
      ;;

    *)
      echo "Invalid risk value. Stopping with trust score preserved."
      echo "Verifier log: $verifier_log"
      cycle_summary "$cycle" "$risk" "$trust" "Verifier risk output invalid"
      exit 1
      ;;
  esac

  cycle="$((cycle + 1))"
done

echo "Completed $RNF_MAX_CYCLES cycle(s). Final trust score: $(read_number "$TRUST_FILE" 0)"
echo "Reason for stopping: RNF_MAX_CYCLES reached"
