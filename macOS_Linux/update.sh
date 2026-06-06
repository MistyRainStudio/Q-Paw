#!/bin/bash
# ============================================
#  Q-Paw Update Script (macOS / Linux)
#  Updates QwenPaw and modelscope
#  uv is NOT updated — keep the bundled version stable
#  Package manager: uv (default) + pip (fallback)
#  Mirrors: China-first
# ============================================

USB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

OS_NAME="$(uname -s)"
ARCH="$(uname -m)"

echo ""
echo -e "${CYAN} =============================================${NC}"
echo -e "${CYAN}   Q-Paw Update${NC}"
echo -e "${CYAN}   Package manager: uv (fast) / pip (fallback)${NC}"
echo -e "${CYAN}   Mirrors: China-first${NC}"
echo -e "${CYAN} =============================================${NC}"
echo ""

# --- Detect Python ---
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
    echo -e "${RED}[ERROR] Portable Python not found!${NC}"
    echo " Please run setup.sh first."
    exit 1
fi

# Set environment
export PYTHONHOME="$PYTHON_DIR"
PY_VER=$("$PYTHON_BIN" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
export PYTHONPATH="$PYTHONHOME/lib:$PYTHONHOME/lib/python${PY_VER}/site-packages:$USB_ROOT/qwenpaw-packages"
export PATH="$USB_ROOT/bin:$PYTHONHOME/bin:$PATH"
export QWENPAW_WORKING_DIR="$USB_ROOT/data"
export QP_PORTABLE_MODE=1
export QP_MODELS_DIR="$USB_ROOT/models"

# Detect package manager (use existing uv, don't update it)
UV_BIN="$USB_ROOT/bin/uv"
PKG_CMD="pip"
if [ -f "$UV_BIN" ]; then
    PKG_CMD="uv"
    echo -e " uv detected:"
    "$UV_BIN" --version
else
    echo -e " ${YELLOW}uv not found, using pip.${NC}"
fi
echo -e " Package manager: ${GREEN}${PKG_CMD}${NC}"
echo ""

# --- Step 1: Update QwenPaw ---
echo -e " [1/2] Updating QwenPaw..."

echo " Current version:"
"$PYTHON_BIN" -c "import importlib.metadata; print(importlib.metadata.version('qwenpaw'))" 2>/dev/null || echo "  (not installed)"

QP_UPDATED=false

if [ "$PKG_CMD" = "uv" ] && [ -f "$UV_BIN" ]; then
    echo " Updating with uv (fast)..."
    echo " Mirror: Aliyun"

    if "$UV_BIN" pip install --upgrade qwenpaw --python "$PYTHON_BIN" --index-url https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com; then
        QP_UPDATED=true
    elif "$UV_BIN" pip install --upgrade qwenpaw --python "$PYTHON_BIN" --index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn; then
        QP_UPDATED=true
    elif "$UV_BIN" pip install --upgrade qwenpaw --python "$PYTHON_BIN" --index-url https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com; then
        QP_UPDATED=true
    else
        echo " uv + all mirrors failed, falling back to pip..."
    fi
fi

if [ "$QP_UPDATED" = false ]; then
    echo " Updating with pip (fallback)..."
    echo " Mirror order: Aliyun -> Tsinghua -> HuaweiCloud -> Official"

    if "$PYTHON_DIR/bin/pip" install --upgrade qwenpaw -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com; then
        QP_UPDATED=true
    elif "$PYTHON_DIR/bin/pip" install --upgrade qwenpaw -i https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn; then
        QP_UPDATED=true
    elif "$PYTHON_DIR/bin/pip" install --upgrade qwenpaw -i https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com; then
        QP_UPDATED=true
    elif "$PYTHON_DIR/bin/pip" install --upgrade qwenpaw; then
        QP_UPDATED=true
    fi
fi

if [ "$QP_UPDATED" = true ]; then
    echo ""
    echo " New version:"
    "$PYTHON_BIN" -c "import importlib.metadata; print(importlib.metadata.version('qwenpaw'))" 2>/dev/null || echo "  (unknown)"
    echo -e " ${GREEN}OK - QwenPaw updated.${NC}"
else
    echo -e "${RED} [ERROR] QwenPaw update failed! Check your network.${NC}"
    exit 1
fi
echo ""

# --- Step 2: Update modelscope ---
echo -e " [2/2] Updating modelscope..."

MS_UPDATED=false

if [ "$PKG_CMD" = "uv" ] && [ -f "$UV_BIN" ]; then
    if "$UV_BIN" pip install --upgrade modelscope --python "$PYTHON_BIN" --index-url https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com; then
        MS_UPDATED=true
    elif "$UV_BIN" pip install --upgrade modelscope --python "$PYTHON_BIN" --index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn; then
        MS_UPDATED=true
    else
        echo " uv failed, falling back to pip..."
    fi
fi

if [ "$MS_UPDATED" = false ]; then
    if "$PYTHON_DIR/bin/pip" install --upgrade modelscope -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com; then
        MS_UPDATED=true
    elif "$PYTHON_DIR/bin/pip" install --upgrade modelscope -i https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn; then
        MS_UPDATED=true
    elif "$PYTHON_DIR/bin/pip" install --upgrade modelscope; then
        MS_UPDATED=true
    fi
fi

if [ "$MS_UPDATED" = true ]; then
    echo -e " ${GREEN}OK - modelscope updated.${NC}"
else
    echo -e " ${YELLOW}[WARN] modelscope update failed, but QwenPaw should still work.${NC}"
fi
echo ""

# --- Done ---
echo -e "${CYAN} =============================================${NC}"
echo -e "${CYAN}   Update Complete!${NC}"
echo -e "${CYAN} =============================================${NC}"
echo ""
echo -e " Run ${GREEN}macOS_Linux/launch.sh${NC} to start QwenPaw."
echo ""
