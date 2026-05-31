#!/bin/bash
# Q-Paw Interactive Configuration Editor
# Calls the Python-based config editor

USB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Detect OS and Python ---
OS_NAME="$(uname -s)"
PYTHON_DIR=""
if [ "$OS_NAME" = "Darwin" ]; then
    PYTHON_DIR="$USB_ROOT/python-macos"
else
    PYTHON_DIR="$USB_ROOT/python-linux"
fi

PYTHON_BIN="$PYTHON_DIR/bin/python3"

if [ ! -f "$PYTHON_BIN" ]; then
    echo ""
    echo " [ERROR] Portable Python not found! Please run setup.sh first."
    echo ""
    exit 1
fi

# --- Set environment ---
export PYTHONHOME="$PYTHON_DIR"
export QWENPAW_WORKING_DIR="$USB_ROOT/data"
export QWENPAW_SECRET_DIR="$USB_ROOT/data/.secret"
export QWENPAW_BACKUP_DIR="$USB_ROOT/data/.backups"
export USB_ROOT="$USB_ROOT"

# --- Launch config editor ---
"$PYTHON_BIN" "$USB_ROOT/scripts/qpaw-config.py"
