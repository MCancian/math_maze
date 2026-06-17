#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-$HOME/.local/bin/godot}"
cd "$ROOT"

"$GODOT" --headless --editor --quit --path .
"$GODOT" --headless --path . -s res://tools/test_save_and_level.gd
"$GODOT" --headless --path . res://tools/test_runtime.tscn
