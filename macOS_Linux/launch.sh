#!/bin/bash
# ============================================
#  Q-Paw Portable Launcher (macOS / Linux)
#  Supports uv (fast) + pip (fallback)
#  Models are NOT downloaded by default
# ============================================

# Note: NOT using set -e because qwenpaw desktop may fail and we want to fallback

# --- Get USB root directory ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
USB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# --- Colors ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Detect OS ---
OS_NAME="$(uname -s)"
ARCH="$(uname -m)"

# --- Check portable Python ---
PYTHON_DIR=""
if [ "$OS_NAME" = "Darwin" ]; then
    PYTHON_DIR="$USB_ROOT/python-macos"
elif [ "$OS_NAME" = "Linux" ]; then
    PYTHON_DIR="$USB_ROOT/python-linux"
else
    echo -e "${RED}Unsupported OS: $OS_NAME${NC}"
    exit 1
fi

PYTHON_BIN="$PYTHON_DIR/bin/python3"

if [ ! -f "$PYTHON_BIN" ]; then
    echo ""
    echo -e "${RED}[ERROR] Portable Python not found!${NC}"
    echo " Please run setup.sh first."
    echo ""
    exit 1
fi

# --- Set portable Python environment ---
export PYTHONHOME="$PYTHON_DIR"

# Auto-detect Python version for correct site-packages path
PY_VER=$("$PYTHON_BIN" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
export PYTHONPATH="$PYTHONHOME/lib:$PYTHONHOME/lib/python${PY_VER}/site-packages:$USB_ROOT/qwenpaw-packages"
export PATH="$USB_ROOT/bin:$PYTHONHOME/bin:$PATH"

# --- Core portable setting: QwenPaw working directory on USB ---
export QWENPAW_WORKING_DIR="$USB_ROOT/data"
export QWENPAW_SECRET_DIR="$USB_ROOT/data/.secret"
export QWENPAW_BACKUP_DIR="$USB_ROOT/data/.backups"

# --- Redirect all caches to USB (no traces on host PC) ---
export PIP_CACHE_DIR="$USB_ROOT/cache/pip"
export UV_CACHE_DIR="$USB_ROOT/cache/uv"
export MODELSCOPE_CACHE="$USB_ROOT/cache/modelscope"
export HUGGINGFACE_HUB_CACHE="$USB_ROOT/cache/huggingface"

# --- Portable mode flags ---
export QP_PORTABLE_MODE=1
export QP_MODELS_DIR="$USB_ROOT/models"

# --- Ensure directories exist ---
mkdir -p "$QWENPAW_WORKING_DIR" "$QWENPAW_SECRET_DIR" "$QWENPAW_BACKUP_DIR"
mkdir -p "$PIP_CACHE_DIR" "$UV_CACHE_DIR" "$MODELSCOPE_CACHE" "$HUGGINGFACE_HUB_CACHE"
mkdir -p "$QP_MODELS_DIR"

# --- Ensure pip is available (AI may call pip directly) ---
"$PYTHON_BIN" -m pip --version >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e " ${YELLOW}[INFO] pip not found, installing via uv...${NC}"
    if [ -f "$UV_BIN" ]; then
        if "$UV_BIN" pip install pip --python "$PYTHON_BIN" --index-url https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com; then
            echo -e " ${GREEN}pip installed via uv.${NC}"
        else
            echo -e " ${YELLOW}uv failed, trying get-pip.py...${NC}"
            curl -L -o /tmp/get-pip.py "https://bootstrap.pypa.io/get-pip.py" --connect-timeout 15 -s
            "$PYTHON_BIN" /tmp/get-pip.py --no-warn-script-location -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
            rm -f /tmp/get-pip.py
            echo -e " ${GREEN}pip installed.${NC}"
        fi
    else
        curl -L -o /tmp/get-pip.py "https://bootstrap.pypa.io/get-pip.py" --connect-timeout 15 -s
        "$PYTHON_BIN" /tmp/get-pip.py --no-warn-script-location -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com
        rm -f /tmp/get-pip.py
        echo -e " ${GREEN}pip installed.${NC}"
    fi
fi

# --- Check if QwenPaw workspace is initialized ---
if [ ! -f "$QWENPAW_WORKING_DIR/config.json" ]; then
    echo ""
    echo -e "${YELLOW}[WARN] QwenPaw workspace not initialized!${NC}"
    echo -e "       Please run ${GREEN}setup.sh${NC} first, or run: ${GREEN}qwenpaw init --defaults${NC}"
    echo ""
    exit 1
fi

# --- Display info ---
echo ""
echo -e "${CYAN} =============================================${NC}"
echo -e "${CYAN}   Q-Paw Portable - QwenPaw USB Launcher${NC}"
echo -e "${CYAN} =============================================${NC}"
echo ""
echo -e " USB Root:   ${GREEN}$USB_ROOT${NC}"
echo -e " Python:     ${GREEN}$PYTHON_BIN${NC}"
echo -e " Work Dir:   ${GREEN}$QWENPAW_WORKING_DIR${NC}"
echo -e " Secret Dir: ${GREEN}$QWENPAW_SECRET_DIR${NC}"
echo -e " Models Dir: ${GREEN}$QP_MODELS_DIR${NC}"

# --- Show package manager ---
if [ -f "$USB_ROOT/bin/uv" ]; then
    echo -e " Pkg Mgr:    ${GREEN}uv (fast)${NC}"
else
    echo -e " Pkg Mgr:    ${YELLOW}pip${NC}"
fi
echo ""

# --- Check models directory ---
MODEL_COUNT=$(ls -1 "$QP_MODELS_DIR" 2>/dev/null | wc -l | tr -d ' ')
if [ "$MODEL_COUNT" = "0" ]; then
    echo -e "${YELLOW} [INFO] No local models found. Online mode will be used.${NC}"
    echo -e "        Run ${GREEN}model-manager.sh${NC} to download or import models."
    echo ""
fi

# --- Launch QwenPaw ---
echo -e " Starting QwenPaw..."
echo ""

# Try desktop version first
DESKTOP_APP=""
if [ "$OS_NAME" = "Darwin" ]; then
    DESKTOP_APP="$USB_ROOT/qwenpaw-desktop/QwenPaw.app"
else
    DESKTOP_APP="$USB_ROOT/qwenpaw-desktop/QwenPaw"
fi

if [ -e "$DESKTOP_APP" ]; then
    open "$DESKTOP_APP" 2>/dev/null || "$DESKTOP_APP" 2>/dev/null
    echo -e "${GREEN} Desktop version launched!${NC}"
else
    # CLI version - desktop mode with webview, fallback to app mode
    "$PYTHON_BIN" -m qwenpaw desktop 2>&1 || "$PYTHON_BIN" -m qwenpaw app 2>&1
fi

echo ""
