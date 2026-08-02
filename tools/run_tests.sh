#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot4}"
IF_TEST_RUNTIME_DIR="${IF_TEST_RUNTIME_DIR:-/tmp/infinite-frontier-godot-runtime}"
IF_TEST_LOG_DIR="$IF_TEST_RUNTIME_DIR/logs"

mkdir -p "$IF_TEST_RUNTIME_DIR/data" "$IF_TEST_RUNTIME_DIR/config" "$IF_TEST_RUNTIME_DIR/cache" "$IF_TEST_LOG_DIR"
export XDG_DATA_HOME="$IF_TEST_RUNTIME_DIR/data"
export XDG_CONFIG_HOME="$IF_TEST_RUNTIME_DIR/config"
export XDG_CACHE_HOME="$IF_TEST_RUNTIME_DIR/cache"

python3 "$PROJECT_ROOT/tools/verify_project.py"

run_godot_check() {
  local log_name="$1"
  shift
  local log_path="$IF_TEST_LOG_DIR/$log_name.log"
  set +e
  "$GODOT_BIN" "$@" 2>&1 | tee "$log_path"
  local command_status="${PIPESTATUS[0]}"
  set -e
  if [[ "$command_status" -ne 0 ]]; then
    return "$command_status"
  fi
	if rg -q 'SCRIPT ERROR|^ERROR:|CrashHandlerException|ObjectDB instances were leaked' "$log_path"; then
    echo "Godot reported an error in $log_path" >&2
    return 1
  fi
	if rg -q '=== [0-9]+ passed, [1-9][0-9]* failed ===' "$log_path"; then
		echo "Automated suite reported a failed assertion in $log_path" >&2
		return 1
	fi
}

run_godot_check import --headless --path "$PROJECT_ROOT" --editor --quit
run_godot_check tests --headless --path "$PROJECT_ROOT" res://tests/test_runner.tscn
run_godot_check smoke --headless --path "$PROJECT_ROOT" --quit-after 3
run_godot_check game-smoke --headless --path "$PROJECT_ROOT" --scene res://scenes/main/game.tscn --quit-after 3
