#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/venv.sh"
run_in_venv "$SCRIPT_DIR/find_regions.py" "$@"
exit $?
