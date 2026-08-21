#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/../lib/venv.sh"
GIO_USE_VFS=local run_in_venv "$SCRIPT_DIR/thumbgen.py" "$@"
exit $?
