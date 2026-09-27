#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/../.venv"

# If cocotb is not found in PATH and .venv does not exist, set it up automatically
if ! command -v cocotb-config &> /dev/null && [ ! -f "${VENV_DIR}/bin/cocotb-config" ]; then
    echo "=================================================================="
    echo "[SETUP] cocotb not found. Setting up virtual environment in .venv..."
    echo "=================================================================="
    python3 -m venv "${VENV_DIR}"
    "${VENV_DIR}/bin/pip" install --upgrade pip --quiet
    "${VENV_DIR}/bin/pip" install cocotb numpy pytest --quiet
    echo "[SETUP] Virtual environment ready. Proceeding to simulation..."
    echo "=================================================================="
fi

# Add local .venv to PATH if present
if [ -d "${VENV_DIR}/bin" ]; then
    export PATH="${VENV_DIR}/bin:${PATH}"
fi

make -C "${SCRIPT_DIR}" SIM=modelsim "$@"
