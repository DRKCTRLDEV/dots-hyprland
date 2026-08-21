#!/usr/bin/env bash

run_in_venv() {
    source "$(eval echo "$ILLOGICAL_IMPULSE_VIRTUAL_ENV")/bin/activate"
    "$@"
    local exit_code=$?
    deactivate
    return $exit_code
}
