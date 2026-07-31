#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot4}"
IF_TEST_RUNTIME_DIR="${IF_TEST_RUNTIME_DIR:-/tmp/infinite-frontier-godot-runtime}"

mkdir -p "$IF_TEST_RUNTIME_DIR/data" "$IF_TEST_RUNTIME_DIR/config" "$IF_TEST_RUNTIME_DIR/cache"
export XDG_DATA_HOME="$IF_TEST_RUNTIME_DIR/data"
export XDG_CONFIG_HOME="$IF_TEST_RUNTIME_DIR/config"
export XDG_CACHE_HOME="$IF_TEST_RUNTIME_DIR/cache"

python3 "$PROJECT_ROOT/tools/verify_project.py"
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --editor --quit
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" res://tests/test_runner.tscn
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --quit-after 3
