#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../../scripts/lib/venv.sh"
run_in_venv "$SCRIPT_DIR/token_from_key.py"
exit $?
