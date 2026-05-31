#!/bin/bash
# ============================================
#  Q-Paw Skill Dependencies Installer
#  Auto-installs Python packages needed by
#  QwenPaw's default skills
#  Package manager: uv (preferred) / pip (fallback)
#  Mirrors: China-first
# ============================================

USB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

# --- Detect Python ---
OS_NAME="$(uname -s)"
if [ "$OS_NAME" = "Darwin" ]; then
    PYTHON_BIN="$USB_ROOT/python-macos/bin/python3"
    PIP_BIN="$USB_ROOT/python-macos/bin/pip"
elif [ "$OS_NAME" = "Linux" ]; then
    PYTHON_BIN="$USB_ROOT/python-linux/bin/python3"
    PIP_BIN="$USB_ROOT/python-linux/bin/pip"
else
    echo -e "${RED}Unsupported OS: $OS_NAME${NC}"
    exit 1
fi

UV_BIN="$USB_ROOT/bin/uv"

# Detect package manager
if [ -f "$UV_BIN" ]; then
    PKG_MGR="uv"
else
    PKG_MGR="pip"
fi

# --- Redirect caches to USB ---
export PIP_CACHE_DIR="$USB_ROOT/cache/pip"
export UV_CACHE_DIR="$USB_ROOT/cache/uv"
mkdir -p "$PIP_CACHE_DIR" "$UV_CACHE_DIR"

# --- Counters ---
TOTAL_INSTALL=0
TOTAL_SKIP=0
TOTAL_FAIL=0

# =============================================
# Function: Install a Python package
# =============================================
install_pkg() {
    local PKG="$1"
    local IMPORT_NAME="${PKG%%[*}"           # strip extras like [pptx]
    IMPORT_NAME="${IMPORT_NAME//-/_}"         # dash -> underscore for import

    # Check if already installed
    if "$PYTHON_BIN" -c "import $IMPORT_NAME" 2>/dev/null; then
        local VER
        VER=$("$PYTHON_BIN" -c "import $IMPORT_NAME; print($IMPORT_NAME.__version__)" 2>/dev/null || echo "?")
        echo -e "    ${DIM}[SKIP]${NC} $PKG already installed $VER"
        TOTAL_SKIP=$((TOTAL_SKIP + 1))
        return 0
    fi

    echo -e "    Installing ${BOLD}$PKG${NC} ..."

    local INSTALLED=0

    # Try uv first (10-100x faster)
    if [ "$PKG_MGR" = "uv" ]; then
        if "$UV_BIN" pip install "$PKG" --python "$PYTHON_BIN" \
            --index-url https://mirrors.aliyun.com/pypi/simple/ \
            --trusted-host mirrors.aliyun.com 2>/dev/null; then
            INSTALLED=1
        elif "$UV_BIN" pip install "$PKG" --python "$PYTHON_BIN" \
            --index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ \
            --trusted-host mirrors.tuna.tsinghua.edu.cn 2>/dev/null; then
            INSTALLED=1
        elif "$UV_BIN" pip install "$PKG" --python "$PYTHON_BIN" \
            --index-url https://repo.huaweicloud.com/repository/pypi/simple/ \
            --trusted-host repo.huaweicloud.com 2>/dev/null; then
            INSTALLED=1
        else
            echo -e "    ${YELLOW}uv failed, trying pip fallback...${NC}"
        fi
    fi

    # Fallback to pip
    if [ "$INSTALLED" = "0" ]; then
        if "$PIP_BIN" install "$PKG" \
            -i https://mirrors.aliyun.com/pypi/simple/ \
            --trusted-host mirrors.aliyun.com 2>/dev/null; then
            INSTALLED=1
        elif "$PIP_BIN" install "$PKG" \
            -i https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ \
            --trusted-host mirrors.tuna.tsinghua.edu.cn 2>/dev/null; then
            INSTALLED=1
        elif "$PIP_BIN" install "$PKG" \
            -i https://repo.huaweicloud.com/repository/pypi/simple/ \
            --trusted-host repo.huaweicloud.com 2>/dev/null; then
            INSTALLED=1
        elif "$PIP_BIN" install "$PKG" 2>/dev/null; then
            INSTALLED=1
        fi
    fi

    if [ "$INSTALLED" = "1" ]; then
        echo -e "    ${GREEN}[OK]${NC}   $PKG installed"
        TOTAL_INSTALL=$((TOTAL_INSTALL + 1))
    else
        echo -e "    ${RED}[FAIL]${NC} $PKG installation failed!"
        TOTAL_FAIL=$((TOTAL_FAIL + 1))
        return 1
    fi
    return 0
}

# =============================================
# Main
# =============================================

echo ""
echo -e " ${CYAN}═════════════════════════════════════════════${NC}"
echo -e " ${CYAN}  Q-Paw Skill Dependencies Installer${NC}"
echo -e " ${CYAN}  Package manager: ${GREEN}${PKG_MGR}${NC}"
echo -e " ${CYAN}═════════════════════════════════════════════${NC}"
echo ""
echo " Scanning QwenPaw default skills..."
echo ""

# --- PDF Skill ---
echo -e " ${BOLD}[PDF Skill]${NC} pypdf, pdfplumber, reportlab, pdf2image"
install_pkg "pypdf"
install_pkg "pdfplumber"
install_pkg "reportlab"
install_pkg "pdf2image"

# --- DOCX Skill ---
echo ""
echo -e " ${BOLD}[DOCX Skill]${NC} defusedxml, lxml"
install_pkg "defusedxml"
install_pkg "lxml"

# --- PPTX Skill ---
echo ""
echo -e " ${BOLD}[PPTX Skill]${NC} markitdown[pptx]"
install_pkg "markitdown[pptx]"

# --- XLSX Skill ---
echo ""
echo -e " ${BOLD}[XLSX Skill]${NC} openpyxl, pandas"
install_pkg "openpyxl"
install_pkg "pandas"

# --- Optional: System tools check ---
echo ""
echo -e " ${DIM}───────────────────────────────────────────${NC}"
echo -e " ${DIM}System Tool Check (optional, for full skill support):${NC}"
echo -e " ${DIM}───────────────────────────────────────────${NC}"
echo ""

check_tool() {
    local name="$1"
    local desc="$2"
    if command -v "$name" >/dev/null 2>&1; then
        echo -e "    ${GREEN}$name${NC}: OK"
    else
        echo -e "    ${RED}$name${NC}: NOT FOUND — $desc"
    fi
}

check_tool "pdftotext"  "install poppler-utils for PDF text extraction"
check_tool "pdftoppm"   "install poppler-utils for PDF/image conversion"
check_tool "soffice"    "install LibreOffice for DOCX/PPTX/XLSX conversion"
check_tool "qpdf"       "install qpdf for PDF merge/split/decrypt"
check_tool "pandoc"     "install pandoc for text extraction"

# --- macOS Homebrew hints ---
if [ "$OS_NAME" = "Darwin" ]; then
    echo ""
    echo -e " ${DIM}macOS install hints:${NC}"
    echo -e " ${DIM}  brew install poppler qpdf pandoc libreoffice${NC}"
fi

# =============================================
# Summary
# =============================================
echo ""
echo -e " ${CYAN}═════════════════════════════════════════════${NC}"
echo -e " ${CYAN}  Installation Summary${NC}"
echo -e " ${CYAN}═════════════════════════════════════════════${NC}"
echo ""
echo -e "    Installed: ${GREEN}${TOTAL_INSTALL}${NC}"
echo -e "    Skipped:   ${DIM}${TOTAL_SKIP}${NC}  (already installed)"
echo -e "    Failed:    ${RED}${TOTAL_FAIL}${NC}"
echo ""

if [ "$TOTAL_FAIL" = "0" ]; then
    echo -e "    ${GREEN}All Python dependencies installed successfully!${NC}"
else
    echo -e "    ${YELLOW}Some packages failed. Try running this script again.${NC}"
fi

echo ""
echo " NOTE: System tools (LibreOffice, poppler, etc.) need to be"
echo "       installed separately on the host OS. They are optional"
echo "       but recommended for full document skill support."
echo ""
