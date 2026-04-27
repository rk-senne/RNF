#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="/Users/regosenne/Desktop/Dev/RNF"
STATE_DIR="$ROOT_DIR/.rnf"
LOG_DIR="$STATE_DIR/logs"
TRUST_FILE="$STATE_DIR/trust_score"
BUILDER_PROMPT="$ROOT_DIR/scripts/rnf_builder_prompt.txt"
VERIFIER_PROMPT="$ROOT_DIR/scripts/rnf_verifier_prompt.txt"
TASK_GRAPH="$ROOT_DIR/RNF/Docs/task_graph.md"

CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_MODEL="${CODEX_MODEL:-}"
RNF_MAX_CYCLES="${RNF_MAX_CYCLES:-1}"
TRUST_MAX="${TRUST_MAX:-100}"

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

read_trust() {
  if [[ -f "$TRUST_FILE" ]]; then
    local value
    value="$(tr -d '[:space:]' < "$TRUST_FILE")"
    if [[ "$value" =~ ^[0-9]+$ ]]; then
      echo "$value"
      return
    fi
  fi
  echo "0"
}

write_trust() {
  printf '%s\n' "$1" > "$TRUST_FILE"
}

codex_exec() {
  local prompt_file="$1"
  local output_file="$2"
  local prompt
  prompt="$(cat "$prompt_file")"

  if [[ -n "$CODEX_MODEL" ]]; then
    (cd "$ROOT_DIR" && "$CODEX_BIN" exec --model "$CODEX_MODEL" "$prompt") | tee "$output_file"
  else
    (cd "$ROOT_DIR" && "$CODEX_BIN" exec "$prompt") | tee "$output_file"
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

require_file "$BUILDER_PROMPT"
require_file "$VERIFIER_PROMPT"
require_file "$TASK_GRAPH"
require_int "RNF_MAX_CYCLES" "$RNF_MAX_CYCLES"
require_int "TRUST_MAX" "$TRUST_MAX"

trust="$(read_trust)"
write_trust "$trust"

cycle=1
while [[ "$cycle" -le "$RNF_MAX_CYCLES" ]]; do
  stamp="$(date -u '+%Y%m%dT%H%M%SZ')"
  builder_log="$LOG_DIR/${stamp}_cycle_${cycle}_builder.log"
  verifier_log="$LOG_DIR/${stamp}_cycle_${cycle}_verifier.log"

  echo "RNF cycle $cycle/$RNF_MAX_CYCLES"
  echo "Trust score: $trust"

  if ! codex_exec "$BUILDER_PROMPT" "$builder_log"; then
    echo "Builder failed. Stopping and resetting trust."
    write_trust "0"
    echo "Builder log: $builder_log"
    exit 1
  fi

  if ! codex_exec "$VERIFIER_PROMPT" "$verifier_log"; then
    echo "Verifier failed. Stopping and resetting trust."
    write_trust "0"
    echo "Verifier log: $verifier_log"
    exit 1
  fi

  risk="$(extract_risk "$verifier_log")"
  echo "Verifier risk: $risk"

  case "$risk" in
    LOW)
      if [[ "$trust" -lt "$TRUST_MAX" ]]; then
        trust="$((trust + 1))"
      fi
      write_trust "$trust"
      echo "Trust score updated: $trust"
      ;;
    MEDIUM)
      echo "MEDIUM risk. Stopping with trust score preserved."
      echo "Verifier log: $verifier_log"
      exit 0
      ;;
    HIGH)
      echo "HIGH risk. Stopping and resetting trust."
      write_trust "0"
      echo "Verifier log: $verifier_log"
      exit 1
      ;;
    *)
      echo "Invalid risk value. Stopping with trust score preserved."
      echo "Verifier log: $verifier_log"
      exit 1
      ;;
  esac

  cycle="$((cycle + 1))"
done

echo "Completed $RNF_MAX_CYCLES cycle(s). Final trust score: $(read_trust)"
