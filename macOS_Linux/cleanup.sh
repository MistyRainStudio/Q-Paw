#!/bin/bash
# ============================================
#  Q-Paw Cleanup Utility (macOS / Linux)
#  Supports uv + pip cache cleanup
#  Clean caches and logs to free USB space
# ============================================

USB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN} =============================================${NC}"
echo -e "${CYAN}   Q-Paw Cleanup Utility${NC}"
echo -e "${CYAN}   (uv + pip cache supported)${NC}"
echo -e "${CYAN} =============================================${NC}"
echo ""
echo " Choose what to clean:"
echo ""
echo "   1. Clean log files"
echo "   2. Clean Python cache"
echo "   3. Clean pip cache"
echo "   4. Clean uv cache"
echo "   5. Clean temp files"
echo "   6. Clean all - above items"
echo "   0. Exit"
echo ""
read -p "  Enter choice: " CHOICE

case $CHOICE in
    1)
        echo " Cleaning logs..."
        rm -f "$USB_ROOT/logs/"* 2>/dev/null
        echo -e " ${GREEN}Done.${NC}"
        ;;
    2)
        echo " Cleaning Python cache..."
        find "$USB_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
        find "$USB_ROOT" -name "*.pyc" -delete 2>/dev/null
        echo -e " ${GREEN}Done.${NC}"
        ;;
    3)
        echo " Cleaning pip cache..."
        PIP_BIN=""
        OS_NAME="$(uname -s)"
        if [ "$OS_NAME" = "Darwin" ]; then
            PIP_BIN="$USB_ROOT/python-macos/bin/pip"
        else
            PIP_BIN="$USB_ROOT/python-linux/bin/pip"
        fi
        if [ -f "$PIP_BIN" ]; then
            "$PIP_BIN" cache purge 2>/dev/null
        fi
        rm -rf "$USB_ROOT/python-macos/pip-cache" "$USB_ROOT/python-linux/pip-cache" 2>/dev/null
        echo -e " ${GREEN}Done.${NC}"
        ;;
    4)
        echo " Cleaning uv cache..."
        UV_BIN="$USB_ROOT/bin/uv"
        if [ -f "$UV_BIN" ]; then
            "$UV_BIN" cache clean 2>/dev/null
            echo -e " uv cache cleaned."
        else
            echo " uv not found, skipping."
        fi
        rm -rf "$USB_ROOT/bin/.uv-cache" 2>/dev/null
        echo -e " ${GREEN}Done.${NC}"
        ;;
    5)
        echo " Cleaning temp files..."
        rm -f "$USB_ROOT/"*.tmp 2>/dev/null
        rm -f "$USB_ROOT/"*.log 2>/dev/null
        rm -rf "$USB_ROOT/temp" 2>/dev/null
        echo -e " ${GREEN}Done.${NC}"
        ;;
    6)
        echo " Running full cleanup..."
        # Logs
        rm -f "$USB_ROOT/logs/"* 2>/dev/null
        # Python cache
        find "$USB_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null
        find "$USB_ROOT" -name "*.pyc" -delete 2>/dev/null
        # pip cache
        PIP_BIN=""
        OS_NAME="$(uname -s)"
        if [ "$OS_NAME" = "Darwin" ]; then
            PIP_BIN="$USB_ROOT/python-macos/bin/pip"
        else
            PIP_BIN="$USB_ROOT/python-linux/bin/pip"
        fi
        if [ -f "$PIP_BIN" ]; then
            "$PIP_BIN" cache purge 2>/dev/null
        fi
        rm -rf "$USB_ROOT/python-macos/pip-cache" "$USB_ROOT/python-linux/pip-cache" 2>/dev/null
        # uv cache
        UV_BIN="$USB_ROOT/bin/uv"
        if [ -f "$UV_BIN" ]; then
            "$UV_BIN" cache clean 2>/dev/null
        fi
        rm -rf "$USB_ROOT/bin/.uv-cache" 2>/dev/null
        # Temp
        rm -f "$USB_ROOT/"*.tmp 2>/dev/null
        rm -f "$USB_ROOT/"*.log 2>/dev/null
        rm -rf "$USB_ROOT/temp" 2>/dev/null
        echo -e " ${GREEN}Full cleanup done.${NC}"
        ;;
    *)
        echo " Exiting."
        ;;
esac

echo ""
