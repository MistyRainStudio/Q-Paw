#!/bin/bash
# ============================================
#  Q-Paw Model Manager (macOS / Linux)
#  Supports uv (fast) + pip (fallback)
#  Uses Chinese mirrors for faster downloads
# ============================================

USB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

OS_NAME="$(uname -s)"
if [ "$OS_NAME" = "Darwin" ]; then
    PYTHON_BIN="$USB_ROOT/python-macos/bin/python3"
    PIP_BIN="$USB_ROOT/python-macos/bin/pip"
else
    PYTHON_BIN="$USB_ROOT/python-linux/bin/python3"
    PIP_BIN="$USB_ROOT/python-linux/bin/pip"
fi

UV_BIN="$USB_ROOT/bin/uv"
QP_MODELS_DIR="$USB_ROOT/models"

# Detect package manager
if [ -f "$UV_BIN" ]; then
    PKG_MGR="uv"
else
    PKG_MGR="pip"
fi

while true; do
    echo ""
    echo -e "${CYAN} =============================================${NC}"
    echo -e "${CYAN}   Q-Paw Model Manager${NC}"
    echo -e "${CYAN}   Package manager: ${GREEN}${PKG_MGR}${NC}"
    echo -e "${CYAN} =============================================${NC}"
    echo ""
    echo -e " Models Dir: ${GREEN}$QP_MODELS_DIR${NC}"
    echo ""

    # Show installed models
    echo " [Installed Models]"
    MODEL_COUNT=$(ls -1 "$QP_MODELS_DIR" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$MODEL_COUNT" = "0" ]; then
        echo "    (empty) No local models, using online mode"
    else
        ls -1 "$QP_MODELS_DIR"
    fi
    echo ""
    echo " -------------------------------------------"
    echo " Choose an action:"
    echo ""
    echo "   1. Download model from ModelScope"
    echo "   2. Import model from local files"
    echo "   3. Delete installed model"
    echo "   4. Switch online/offline mode"
    echo "   5. Show disk space"
    echo "   6. Install Python package (uv/pip)"
    echo "   7. Configure download mirror"
    echo "   0. Exit"
    echo ""
    read -p "  Enter choice: " CHOICE

    case $CHOICE in
        1)
            echo ""
            echo " --- Download Model ---"
            echo ""
            echo " Available models:"
            echo ""
            echo "   1. QwenPaw-Flash-2B      (~4GB, recommended)"
            echo "   2. Qwen2.5-7B-Instruct   (~15GB, better quality)"
            echo "   3. Qwen2.5-3B-Instruct   (~6GB, balanced)"
            echo "   4. Qwen2.5-1.5B-Instruct (~3GB, lightweight)"
            echo "   5. Custom model (enter ModelScope path)"
            echo "   0. Back"
            echo ""
            read -p "  Select model: " MODEL_CHOICE

            case $MODEL_CHOICE in
                1)
                    echo ""
                    echo " Downloading QwenPaw-Flash-2B from ModelScope..."
                    "$PYTHON_BIN" -m modelscope download --model AgentScope/QwenPaw-Flash-2B --local_dir "$QP_MODELS_DIR/QwenPaw-Flash-2B" || \
                    "$PYTHON_BIN" -c "from modelscope import snapshot_download; snapshot_download('AgentScope/QwenPaw-Flash-2B', cache_dir='$QP_MODELS_DIR/QwenPaw-Flash-2B')"
                    ;;
                2)
                    echo ""
                    echo " Downloading Qwen2.5-7B-Instruct..."
                    "$PYTHON_BIN" -m modelscope download --model Qwen/Qwen2.5-7B-Instruct --local_dir "$QP_MODELS_DIR/Qwen2.5-7B-Instruct"
                    ;;
                3)
                    echo ""
                    echo " Downloading Qwen2.5-3B-Instruct..."
                    "$PYTHON_BIN" -m modelscope download --model Qwen/Qwen2.5-3B-Instruct --local_dir "$QP_MODELS_DIR/Qwen2.5-3B-Instruct"
                    ;;
                4)
                    echo ""
                    echo " Downloading Qwen2.5-1.5B-Instruct..."
                    "$PYTHON_BIN" -m modelscope download --model Qwen/Qwen2.5-1.5B-Instruct --local_dir "$QP_MODELS_DIR/Qwen2.5-1.5B-Instruct"
                    ;;
                5)
                    echo ""
                    echo " Enter ModelScope model path (format: org/model-name)"
                    read -p "  Model path: " CUSTOM_URL
                    read -p "  Local name: " CUSTOM_NAME
                    echo " Downloading $CUSTOM_NAME from ModelScope..."
                    "$PYTHON_BIN" -m modelscope download --model "$CUSTOM_URL" --local_dir "$QP_MODELS_DIR/$CUSTOM_NAME"
                    ;;
            esac
            echo ""
            echo -e " ${GREEN}Done!${NC}"
            read -p " Press Enter to continue..."
            ;;
        2)
            echo ""
            echo " --- Import Local Model ---"
            read -p "  Source directory path: " IMPORT_PATH
            if [ ! -d "$IMPORT_PATH" ]; then
                echo -e "${RED} [ERROR] Path not found: $IMPORT_PATH${NC}"
                read -p " Press Enter to continue..."
                continue
            fi
            read -p "  Model name (for display): " IMPORT_NAME
            cp -r "$IMPORT_PATH" "$QP_MODELS_DIR/$IMPORT_NAME"
            echo -e " ${GREEN}Done!${NC}"
            read -p " Press Enter to continue..."
            ;;
        3)
            echo ""
            echo " --- Delete Model ---"
            echo " Installed models:"
            ls -1 "$QP_MODELS_DIR" 2>/dev/null
            echo ""
            read -p "  Enter model name to delete: " DEL_NAME
            if [ -d "$QP_MODELS_DIR/$DEL_NAME" ]; then
                rm -rf "$QP_MODELS_DIR/$DEL_NAME"
                echo -e " ${GREEN}Deleted: $DEL_NAME${NC}"
            else
                echo -e "${RED} [ERROR] Model not found: $DEL_NAME${NC}"
            fi
            read -p " Press Enter to continue..."
            ;;
        4)
            echo ""
            echo " --- Switch Mode ---"
            CURRENT_MODE=$(grep "QP_MODEL_MODE" "$USB_ROOT/config/portable.env" 2>/dev/null | cut -d= -f2)
            if [ "$CURRENT_MODE" = "online" ]; then
                echo " Current: ONLINE mode"
                read -p "  Switch to offline mode? (y/n): " SWITCH
                if [ "$SWITCH" = "y" ]; then
                    sed -i '' 's/QP_MODEL_MODE=online/QP_MODEL_MODE=local/' "$USB_ROOT/config/portable.env" 2>/dev/null || \
                    sed -i 's/QP_MODEL_MODE=online/QP_MODEL_MODE=local/' "$USB_ROOT/config/portable.env"
                    echo -e " ${GREEN}Switched to offline mode.${NC}"
                fi
            else
                echo " Current: OFFLINE mode"
                read -p "  Switch to online mode? (y/n): " SWITCH
                if [ "$SWITCH" = "y" ]; then
                    sed -i '' 's/QP_MODEL_MODE=local/QP_MODEL_MODE=online/' "$USB_ROOT/config/portable.env" 2>/dev/null || \
                    sed -i 's/QP_MODEL_MODE=local/QP_MODEL_MODE=online/' "$USB_ROOT/config/portable.env"
                    echo -e " ${GREEN}Switched to online mode.${NC}"
                fi
            fi
            read -p " Press Enter to continue..."
            ;;
        5)
            echo ""
            echo " --- Disk Space ---"
            df -h "$QP_MODELS_DIR" | tail -1
            du -sh "$QP_MODELS_DIR" 2>/dev/null || echo " (empty)"
            read -p " Press Enter to continue..."
            ;;
        6)
            echo ""
            echo " --- Install Python Package ---"
            echo " Using: $PKG_MGR"
            echo ""
            read -p "  Package name: " PKG_NAME
            [ -z "$PKG_NAME" ] && continue

            INSTALLED=0
            if [ "$PKG_MGR" = "uv" ]; then
                echo " Installing with uv (fast)..."
                if "$UV_BIN" pip install "$PKG_NAME" --python "$PYTHON_BIN" --index-url https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com; then
                    INSTALLED=1
                elif "$UV_BIN" pip install "$PKG_NAME" --python "$PYTHON_BIN" --index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/ --trusted-host mirrors.tuna.tsinghua.edu.cn; then
                    INSTALLED=1
                else
                    echo " uv failed, trying pip fallback..."
                fi
            fi
            if [ "$INSTALLED" = "0" ]; then
                if "$PIP_BIN" install "$PKG_NAME" -i https://mirrors.aliyun.com/pypi/simple/ --trusted-host mirrors.aliyun.com; then
                    INSTALLED=1
                elif "$PIP_BIN" install "$PKG_NAME"; then
                    INSTALLED=1
                fi
            fi
            if [ "$INSTALLED" = "1" ]; then
                echo -e " ${GREEN}Installed: $PKG_NAME${NC}"
            else
                echo -e "${RED} [ERROR] Failed to install $PKG_NAME${NC}"
            fi
            read -p " Press Enter to continue..."
            ;;
        7)
            echo ""
            echo " --- Download Mirror Configuration ---"
            echo ""
            echo " Current pip mirror:"
            "$PIP_BIN" config get global.index-url 2>/dev/null || echo "  (default)"
            echo ""
            echo " Available mirrors:"
            echo "   1. Aliyun        - https://mirrors.aliyun.com/pypi/simple/"
            echo "   2. Tsinghua      - https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/"
            echo "   3. Huawei Cloud  - https://repo.huaweicloud.com/repository/pypi/simple/"
            echo "   4. Official      - https://pypi.org/simple/"
            echo "   0. Back"
            echo ""
            read -p "  Select mirror: " MIRROR_CHOICE

            case $MIRROR_CHOICE in
                1)
                    "$PIP_BIN" config set global.index-url https://mirrors.aliyun.com/pypi/simple/
                    "$PIP_BIN" config set global.trusted-host mirrors.aliyun.com
                    echo -e " ${GREEN}Set to Aliyun mirror!${NC}"
                    ;;
                2)
                    "$PIP_BIN" config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/simple/
                    "$PIP_BIN" config set global.trusted-host mirrors.tuna.tsinghua.edu.cn
                    echo -e " ${GREEN}Set to Tsinghua mirror!${NC}"
                    ;;
                3)
                    "$PIP_BIN" config set global.index-url https://repo.huaweicloud.com/repository/pypi/simple/
                    "$PIP_BIN" config set global.trusted-host repo.huaweicloud.com
                    echo -e " ${GREEN}Set to Huawei Cloud mirror!${NC}"
                    ;;
                4)
                    "$PIP_BIN" config unset global.index-url 2>/dev/null
                    echo -e " ${GREEN}Set to official source!${NC}"
                    ;;
            esac
            read -p " Press Enter to continue..."
            ;;
        0)
            exit 0
            ;;
        *)
            continue
            ;;
    esac
done
