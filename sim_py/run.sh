#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "${SCRIPT_DIR}/../.venv/bin" ]; then
    export PATH="${SCRIPT_DIR}/../.venv/bin:${PATH}"
fi
make -C "${SCRIPT_DIR}" SIM=modelsim "$@"
