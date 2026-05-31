#!/bin/bash
# ============================================
#  Q-Paw Setup Script (macOS / Linux)
#  Package manager: uv (default) + pip (fallback)
#  All downloads use Chinese mirrors
#  Models are NOT downloaded by default
# ============================================

set -e

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
echo -e "${CYAN}   Q-Paw Setup - Initializing...${NC}"
echo -e "${CYAN}   Package manager: uv (fast) / pip (fallback)${NC}"
echo -e "${CYAN}   Mirrors: China-first${NC}"
echo -e "${CYAN} =============================================${NC}"
echo ""

# --- Step 1: Install uv ---
echo -e " [1/6] Installing uv package manager..."

UV_BIN="$USB_ROOT/bin/uv"
mkdir -p "$USB_ROOT/bin"

if [ -f "$UV_BIN" ]; then
    echo -e " ${GREEN}OK - uv already installed, skipping.${NC}"
else
    # Determine uv binary URL
    if [ "$OS_NAME" = "Darwin" ]; then
        if [ "$ARCH" = "arm64" ]; then
            UV_URL_MIRROR="https://registry.npmmirror.com/-/binary/uv/0.6.6/uv-aarch64-apple-darwin.tar.gz"
            UV_URL_GH="https://github.com/astral-sh/uv/releases/download/0.6.6/uv-aarch64-apple-darwin.tar.gz"
        else
            UV_URL_MIRROR="https://registry.npmmirror.com/-/binary/uv/0.6.6/uv-x86_64-apple-darwin.tar.gz"
            UV_URL_GH="https://github.com/astral-sh/uv/releases/download/0.6.6/uv-x86_64-apple-darwin.tar.gz"
        fi
    else
        UV_URL_MIRROR="https://registry.npmmirror.com/-/binary/uv/0.6.6/uv-x86_64-unknown-linux-gnu.tar.gz"
        UV_URL_GH="https://github.com/astral-sh/uv/releases/download/0.6.6/uv-x86_64-unknown-linux-gnu.tar.gz"
    fi

    echo " Trying NPMMirror (China)..."
    if curl -L -o /tmp/uv.tar.gz "$UV_URL_MIRROR" --connect-timeout 10 -s -f; then
        tar xzf /tmp/uv.tar.gz -C /tmp/ 2>/dev/null
        # uv tarball extracts to uv-aarch64-.../uv or uv-x86_64-.../uv
        UV_EXTRACTED=$(find /tmp -name "uv" -type f -path "*/uv-*" 2>/dev/null | head -1)
        if [ -n "$UV_EXTRACTED" ] && [ -x "$UV_EXTRACTED" ]; then
            mv "$UV_EXTRACTED" "$UV_BIN"
            chmod +x "$UV_BIN"
            echo -e " ${GREEN}OK - uv installed from NPMMirror.${NC}"
        else
            # Try extracting directly
            tar xzf /tmp/uv.tar.gz -C "$USB_ROOT/bin/" --strip-components=1 2>/dev/null
            if [ -f "$UV_BIN" ]; then
                chmod +x "$UV_BIN"
                echo -e " ${GREEN}OK - uv installed from NPMMirror.${NC}"
            else
                echo " NPMMirror extract failed, trying GitHub..."
                rm -f "$UV_BIN"
            fi
        fi
        rm -f /tmp/uv.tar.gz
    fi

    # If still not installed, try GitHub
    if [ ! -f "$UV_BIN" ]; then
        echo " Trying GitHub..."
        if curl -L -o /tmp/uv.tar.gz "$UV_URL_GH" --connect-timeout 15; then
            tar xzf /tmp/uv.tar.gz -C "$USB_ROOT/bin/" --strip-components=1 2>/dev/null || true
            # Try find approach too
            if [ ! -f "$UV_BIN" ]; then
                tar xzf /tmp/uv.tar.gz -C /tmp/ 2>/dev/null
                UV_EXTRACTED=$(find /tmp -name "uv" -type f -path "*/uv-*" 2>/dev/null | head -1)
                if [ -n "$UV_EXTRACTED" ]; then
                    mv "$UV_EXTRACTED" "$UV_BIN"
                    chmod +x "$UV_BIN"
                fi
            fi
            rm -f /tmp/uv.tar.gz
        fi
    fi

    if [ -f "$UV_BIN" ]; then
        chmod +x "$UV_BIN"
        echo -e " ${GREEN}OK - uv installed.${NC}"
    else
        echo -e " ${YELLOW}[WARN] uv download failed, will use pip instead.${NC}"
        UV_BIN=""
    fi
fi
echo ""

# --- Step 2: Install Miniconda ---
echo -e " [2/6] Checking portable Python..."

PYTHON_DIR=""
if [ "$OS_NAME" = "Darwin" ]; then
    PYTHON_DIR="$USB_ROOT/python-macos"
else
    PYTHON_DIR="$USB_ROOT/python-linux"
fi

PYTHON_BIN="$PYTHON_DIR/bin/python3"

if [ -f "$PYTHON_BIN" ]; then
    echo -e " ${GREEN}OK - Portable Python already exists, skipping.${NC}"
else
    echo " Downloading Miniconda..."

    if [ "$OS_NAME" = "Darwin" ]; then
        if [ "$ARCH" = "arm64" ]; then
            CONDA_URL="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
            CONDA_OFFICIAL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
        else
            CONDA_URL="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
            CONDA_OFFICIAL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
        fi
    else
        CONDA_URL="https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh"
        CONDA_OFFICIAL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    fi

    echo " Trying Tsinghua mirror..."
    if ! curl -L -o /tmp/miniconda.sh "$CONDA_URL" --connect-timeout 15 -s -f; then
        echo " Tsinghua mirror failed, trying official..."
        curl -L -o /tmp/miniconda.sh "$CONDA_OFFICIAL" --connect-timeout 15
    fi

    bash /tmp/miniconda.sh -b -p "$PYTHON_DIR" -s -u
    rm -f /tmp/miniconda.sh

    rm -rf "$PYTHON_DIR/pkgs" "$PYTHON_DIR/doc" "$PYTHON_DIR/info"

    # Configure conda to use Chinese mirror
    cat > "$PYTHON_DIR/.condarc" << 'CONDARC'
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
CONDARC

    echo -e " ${GREEN}OK - Portable Python installed.${NC}"
fi
echo ""

# --- Step 3: Install QwenPaw (uv first, pip fallback) ---
echo -e " [3/6] Installing QwenPaw and dependencies..."
if "$PYTHON_BIN" -c "import qwenpaw" 2>/dev/null; then
    echo -e " ${GREEN}OK - QwenPaw already installed, skipping.${NC}"
    QP_PKG_MGR="existing"
else
    QP_PKG_MGR="none"

    # Try uv first
    if [ -f "$UV_BIN" ]; then
        echo " Installing with uv (10-100x faster than pip)..."
        echo " Mirror: Aliyun"

        if "$UV_BIN" pip install qwenpaw --python "$PYTHON_BIN" --index-url https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com; then
            QP_PKG_MGR="uv"
            echo -e " ${GREEN}OK - QwenPaw installed via uv.${NC}"
        elif "$UV_BIN" pip install qwenpaw --python "$PYTHON_BIN" --index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn; then
            QP_PKG_MGR="uv"
            echo -e " ${GREEN}OK - QwenPaw installed via uv (Tsinghua).${NC}"
        elif "$UV_BIN" pip install qwenpaw --python "$PYTHON_BIN" --index-url https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com; then
            QP_PKG_MGR="uv"
            echo -e " ${GREEN}OK - QwenPaw installed via uv (Huawei).${NC}"
        else
            echo " uv + all mirrors failed, falling back to pip..."
        fi
    fi

    # Fallback to pip
    if [ "$QP_PKG_MGR" = "none" ]; then
        echo " Installing with pip (fallback)..."
        echo " Mirror order: Aliyun -> Tsinghua -> HuaweiCloud -> Official"

        if "$PYTHON_DIR/bin/pip" install qwenpaw -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com; then
            QP_PKG_MGR="pip"
        elif "$PYTHON_DIR/bin/pip" install qwenpaw -i https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn; then
            QP_PKG_MGR="pip"
        elif "$PYTHON_DIR/bin/pip" install qwenpaw -i https://repo.huaweicloud.com/repository/pypi/simple/ --trusted-host repo.huaweicloud.com; then
            QP_PKG_MGR="pip"
        elif "$PYTHON_DIR/bin/pip" install qwenpaw; then
            QP_PKG_MGR="pip"
        else
            echo -e "${RED} [ERROR] QwenPaw installation failed! Check your network.${NC}"
            exit 1
        fi
        echo -e " ${GREEN}OK - QwenPaw installed via pip.${NC}"
    fi
fi
echo ""

# --- Step 4: Create directory structure ---
echo -e " [4/6] Creating portable directories..."
mkdir -p "$USB_ROOT/data"
mkdir -p "$USB_ROOT/config"
mkdir -p "$USB_ROOT/models"
mkdir -p "$USB_ROOT/logs"
mkdir -p "$USB_ROOT/scripts"
mkdir -p "$USB_ROOT/bin"
echo -e " ${GREEN}OK - Directories created.${NC}"
echo ""

# --- Step 5: Generate config ---
echo -e " [5/6] Generating portable config..."
if [ ! -f "$USB_ROOT/config/portable.env" ]; then
    cat > "$USB_ROOT/config/portable.env" << EOF
# Q-Paw Portable Config
QP_PORTABLE_MODE=1
QP_DATA_DIR=$USB_ROOT/data
QP_CONFIG_DIR=$USB_ROOT/config
QP_MODELS_DIR=$USB_ROOT/models
QP_LOG_DIR=$USB_ROOT/logs
# Package manager: uv or pip
QP_PKG_MGR=$QP_PKG_MGR
# Model mode: online or local
QP_MODEL_MODE=online
# Pip mirror for faster installs
QP_PIP_MIRROR=https://mirrors.aliyun.com/pypi/simple/
EOF
    echo -e " ${GREEN}OK - Config generated.${NC}"
else
    echo -e " ${GREEN}OK - Config already exists, skipping.${NC}"
fi
echo ""

# --- Set script executable permissions ---
chmod +x "$USB_ROOT/macOS_Linux/"*.sh "$USB_ROOT/bin/"* 2>/dev/null || true

# --- Step 6: Initialize QwenPaw workspace ---
echo -e " [6/6] Initializing QwenPaw workspace..."

export QWENPAW_WORKING_DIR="$USB_ROOT/data"
export QWENPAW_SECRET_DIR="$USB_ROOT/data/.secret"
export QWENPAW_BACKUP_DIR="$USB_ROOT/data/.backups"

# Redirect all caches to USB (no traces on host PC)
export PIP_CACHE_DIR="$USB_ROOT/cache/pip"
export UV_CACHE_DIR="$USB_ROOT/cache/uv"
export MODELSCOPE_CACHE="$USB_ROOT/cache/modelscope"
export HUGGINGFACE_HUB_CACHE="$USB_ROOT/cache/huggingface"

mkdir -p "$QWENPAW_WORKING_DIR" "$QWENPAW_SECRET_DIR" "$QWENPAW_BACKUP_DIR"
mkdir -p "$PIP_CACHE_DIR" "$UV_CACHE_DIR" "$MODELSCOPE_CACHE" "$HUGGINGFACE_HUB_CACHE"

if [ -f "$QWENPAW_WORKING_DIR/config.json" ]; then
    echo -e " ${GREEN}OK - QwenPaw workspace already initialized, skipping.${NC}"
else
    echo " Running qwenpaw init --defaults..."
    echo " Working directory: $QWENPAW_WORKING_DIR"
    if "$PYTHON_BIN" -m qwenpaw init --defaults; then
        echo -e " ${GREEN}OK - QwenPaw workspace initialized.${NC}"
    else
        echo -e " ${YELLOW}[WARN] qwenpaw init --defaults failed, trying interactive mode...${NC}"
        if "$PYTHON_BIN" -m qwenpaw init; then
            echo -e " ${GREEN}OK - QwenPaw workspace initialized.${NC}"
        else
            echo -e " ${YELLOW}[WARN] QwenPaw init failed. You can run it manually:${NC}"
            echo -e "   export QWENPAW_WORKING_DIR=$USB_ROOT/data"
            echo -e "   python3 -m qwenpaw init"
        fi
    fi
fi
echo ""

# --- Done ---
echo -e "${CYAN} =============================================${NC}"
echo -e "${CYAN}   Setup Complete!${NC}"
echo -e "${CYAN} =============================================${NC}"
echo ""
if [ -f "$UV_BIN" ]; then
    echo -e " Package manager: ${GREEN}uv (fast mode)${NC}"
else
    echo -e " Package manager: ${YELLOW}pip (uv not available)${NC}"
fi
echo -e " Run ${GREEN}macOS_Linux/launch.sh${NC} to start QwenPaw"
echo -e " Run ${GREEN}macOS_Linux/model-manager.sh${NC} to manage models"
echo ""
echo -e " ${CYAN}[TIP] uv is 10-100x faster than pip.${NC}"
echo -e "       If uv failed to install, pip works fine too."
echo ""
