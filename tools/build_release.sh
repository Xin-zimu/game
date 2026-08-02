#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-godot4}"
BUILD_ROOT="${BUILD_ROOT:-$PROJECT_ROOT/build}"
EXPECTED_VERSION="$(sed -n 's/^const VERSION := "\([^"]*\)"/\1/p' "$PROJECT_ROOT/scripts/core/game_version.gd")"
RUNTIME_ROOT="$(mktemp -d /tmp/infinite-frontier-release.XXXXXX)"
SMOKE_LOG="$RUNTIME_ROOT/linux-smoke.log"
IF_BUILD_RUNTIME_DIR="${IF_BUILD_RUNTIME_DIR:-/tmp/infinite-frontier-godot-runtime}"

mkdir -p "$IF_BUILD_RUNTIME_DIR/data" "$IF_BUILD_RUNTIME_DIR/config" "$IF_BUILD_RUNTIME_DIR/cache"
export XDG_DATA_HOME="$IF_BUILD_RUNTIME_DIR/data"
export XDG_CONFIG_HOME="$IF_BUILD_RUNTIME_DIR/config"
export XDG_CACHE_HOME="$IF_BUILD_RUNTIME_DIR/cache"

mkdir -p "$BUILD_ROOT/windows" "$BUILD_ROOT/linux"

"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --export-release "Windows Desktop" "$BUILD_ROOT/windows/InfiniteFrontier.exe"
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --export-release "Linux/X11" "$BUILD_ROOT/linux/InfiniteFrontier.x86_64"

"$BUILD_ROOT/linux/InfiniteFrontier.x86_64" --headless --audio-driver Dummy --quit-after 3 2>&1 | tee "$SMOKE_LOG"
if grep -Eq 'SCRIPT ERROR|^ERROR:|CrashHandlerException|ObjectDB instances were leaked' "$SMOKE_LOG"; then
	echo "Exported Linux build logged an engine or script error." >&2
	exit 1
fi
if ! grep -Fq "version $EXPECTED_VERSION" "$SMOKE_LOG"; then
	echo "Exported Linux build did not report expected version $EXPECTED_VERSION." >&2
	exit 1
fi
if ! file "$BUILD_ROOT/windows/InfiniteFrontier.exe" | grep -Fq "PE32+ executable"; then
	echo "Windows export is not a 64-bit PE executable." >&2
	exit 1
fi
if ! file "$BUILD_ROOT/linux/InfiniteFrontier.x86_64" | grep -Fq "ELF 64-bit"; then
	echo "Linux export is not a 64-bit ELF executable." >&2
	exit 1
fi

echo "Release build verification passed for v$EXPECTED_VERSION."
