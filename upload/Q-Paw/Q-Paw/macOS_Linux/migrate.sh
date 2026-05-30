#!/bin/bash
# ============================================
#  Q-Paw Migration Tool (macOS / Linux)
#  Merges data from an old Q-Paw directory
#  Handles: models, data, config
# ============================================

USB_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo -e "${CYAN} =============================================${NC}"
echo -e "${CYAN}   Q-Paw Migration Tool${NC}"
echo -e "${CYAN}   Merge data from old Q-Paw directory${NC}"
echo -e "${CYAN} =============================================${NC}"
echo ""
echo -e " Current Q-Paw: ${GREEN}$USB_ROOT${NC}"
echo ""

# --- Step 1: Get old Q-Paw path ---
read -p "  Enter old Q-Paw directory path: " OLD_PATH

if [ -z "$OLD_PATH" ]; then
    echo -e "\n ${YELLOW}Migration cancelled.${NC}\n"
    exit 0
fi

# Expand ~ to $HOME
OLD_PATH="${OLD_PATH/#\~/$HOME}"

if [ ! -d "$OLD_PATH" ]; then
    echo -e "\n ${RED}[ERROR] Path not found: $OLD_PATH${NC}"
    echo " Please check the path and try again.\n"
    exit 1
fi

# Remove trailing slash
OLD_PATH="${OLD_PATH%/}"

# Verify it looks like a Q-Paw directory
IS_QPAW=0
if [ -f "$OLD_PATH/launch.bat" ] || [ -f "$OLD_PATH/launch.sh" ]; then IS_QPAW=1; fi
if [ -d "$OLD_PATH/data" ] || [ -d "$OLD_PATH/models" ]; then IS_QPAW=1; fi

if [ "$IS_QPAW" = "0" ]; then
    echo ""
    echo -e " ${YELLOW}[WARN] The path does not look like a Q-Paw directory.${NC}"
    echo "        Expected to find: launch.bat/sh, data/, or models/"
    echo ""
    read -p "  Continue anyway? (y/n): " FORCE
    if [ "$FORCE" != "y" ]; then
        echo -e "\n ${YELLOW}Migration cancelled.${NC}\n"
        exit 0
    fi
fi

echo ""
echo -e " Old Q-Paw: ${GREEN}$OLD_PATH${NC}"
echo ""

# --- Step 2: Scan old directory ---
echo " Scanning old directory..."
echo ""

HAS_MODELS=0
HAS_DATA=0
HAS_CONFIG=0
HAS_LOGS=0

# Check models
if [ -d "$OLD_PATH/models" ]; then
    MODEL_COUNT=$(ls -1 "$OLD_PATH/models" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$MODEL_COUNT" != "0" ]; then
        HAS_MODELS=1
        echo " [Models] Found $MODEL_COUNT model directories:"
        ls -1 "$OLD_PATH/models"
        # Show total size
        MODEL_SIZE=$(du -sh "$OLD_PATH/models" 2>/dev/null | cut -f1)
        echo "          Total size: $MODEL_SIZE"
        echo ""
    fi
fi

# Check data
if [ -d "$OLD_PATH/data" ]; then
    DATA_COUNT=$(ls -1 "$OLD_PATH/data" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$DATA_COUNT" != "0" ]; then
        HAS_DATA=1
        echo " [Data] Found $DATA_COUNT items in data directory:"
        ls -1 "$OLD_PATH/data"
        DATA_SIZE=$(du -sh "$OLD_PATH/data" 2>/dev/null | cut -f1)
        echo "        Total size: $DATA_SIZE"
        echo ""
    fi
fi

# Check config
if [ -f "$OLD_PATH/config/portable.env" ]; then
    HAS_CONFIG=1
    echo " [Config] Found portable.env"
    echo ""
fi

# Check logs
if [ -d "$OLD_PATH/logs" ]; then
    LOG_COUNT=$(ls -1 "$OLD_PATH/logs" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$LOG_COUNT" != "0" ]; then
        HAS_LOGS=1
        echo " [Logs] Found $LOG_COUNT log files"
        echo ""
    fi
fi

# --- Step 3: Choose what to merge ---
echo " -------------------------------------------"
echo " Select what to merge:"
echo ""
echo "   1. Merge all - models + data + config"
echo "   2. Models only"
echo "   3. Data only - chat history, skills, etc."
echo "   4. Config only - portable.env settings"
echo "   5. Custom selection"
echo "   0. Cancel"
echo ""
read -p "  Enter choice: " MERGE_CHOICE

DO_MODELS=0
DO_DATA=0
DO_CONFIG=0

case $MERGE_CHOICE in
    1) DO_MODELS=1; DO_DATA=1; DO_CONFIG=1 ;;
    2) DO_MODELS=1 ;;
    3) DO_DATA=1 ;;
    4) DO_CONFIG=1 ;;
    5)
        if [ "$HAS_MODELS" = "1" ]; then
            read -p "  Merge models? (y/n): " ANS
            [ "$ANS" = "y" ] && DO_MODELS=1
        fi
        if [ "$HAS_DATA" = "1" ]; then
            read -p "  Merge data? (y/n): " ANS
            [ "$ANS" = "y" ] && DO_DATA=1
        fi
        if [ "$HAS_CONFIG" = "1" ]; then
            read -p "  Merge config? (y/n): " ANS
            [ "$ANS" = "y" ] && DO_CONFIG=1
        fi
        ;;
    *) echo -e "\n ${YELLOW}Migration cancelled.${NC}\n"; exit 0 ;;
esac

# --- Step 4: Confirm ---
echo ""
echo -e "${CYAN} =============================================${NC}"
echo -e "${CYAN}   Migration Summary${NC}"
echo -e "${CYAN} =============================================${NC}"
echo ""
echo " Source: $OLD_PATH"
echo " Target: $USB_ROOT"
echo ""
if [ "$DO_MODELS" = "1" ]; then echo " [x] Models - will COPY, skip existing"; else echo " [ ] Models - skipped"; fi
if [ "$DO_DATA" = "1" ]; then echo " [x] Data - will COPY, skip existing"; else echo " [ ] Data - skipped"; fi
if [ "$DO_CONFIG" = "1" ]; then echo " [x] Config - will SMART MERGE"; else echo " [ ] Config - skipped"; fi
echo ""
echo " Strategy: Existing files will NOT be overwritten."
echo " Config values from old version will be preserved"
echo " if they do not exist in the new config."
echo ""
read -p "  Proceed with migration? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo -e "\n ${YELLOW}Migration cancelled.${NC}\n"
    exit 0
fi
echo ""

# =============================================
# Perform Migration
# =============================================

STEP=0
TOTAL=0
[ "$DO_MODELS" = "1" ] && TOTAL=$((TOTAL + 1))
[ "$DO_DATA" = "1" ] && TOTAL=$((TOTAL + 1))
[ "$DO_CONFIG" = "1" ] && TOTAL=$((TOTAL + 1))

# --- Merge Models ---
if [ "$DO_MODELS" = "1" ]; then
    STEP=$((STEP + 1))
    echo -e " [$STEP/$TOTAL] Migrating models..."
    echo ""

    if [ -d "$OLD_PATH/models" ]; then
        mkdir -p "$USB_ROOT/models"

        for model_dir in "$OLD_PATH/models"/*/; do
            if [ -d "$model_dir" ]; then
                model_name=$(basename "$model_dir")
                if [ -d "$USB_ROOT/models/$model_name" ]; then
                    echo -e " ${YELLOW}Skipping existing model: $model_name${NC}"
                else
                    echo " Copying model: $model_name"
                    cp -r "$model_dir" "$USB_ROOT/models/$model_name"
                fi
            fi
        done
    fi

    echo -e " ${GREEN}Models migration done.${NC}"
    echo ""
fi

# --- Merge Data ---
if [ "$DO_DATA" = "1" ]; then
    STEP=$((STEP + 1))
    echo -e " [$STEP/$TOTAL] Migrating data..."
    echo ""

    if [ -d "$OLD_PATH/data" ]; then
        mkdir -p "$USB_ROOT/data"

        # Use rsync if available (better for large files, shows progress)
        if command -v rsync &>/dev/null; then
            echo " Using rsync for efficient copy..."
            rsync -av --ignore-existing "$OLD_PATH/data/" "$USB_ROOT/data/" 2>/dev/null
        else
            echo " Using cp for copy..."
            # cp -n = no overwrite, -r = recursive
            cp -rn "$OLD_PATH/data/"* "$USB_ROOT/data/" 2>/dev/null || true
            # Also handle hidden files
            cp -rn "$OLD_PATH/data/".[!.]* "$USB_ROOT/data/" 2>/dev/null || true
        fi
    fi

    echo -e " ${GREEN}Data migration done.${NC}"
    echo ""
fi

# --- Merge Config ---
if [ "$DO_CONFIG" = "1" ]; then
    STEP=$((STEP + 1))
    echo -e " [$STEP/$TOTAL] Migrating config..."
    echo ""

    if [ -f "$OLD_PATH/config/portable.env" ]; then
        mkdir -p "$USB_ROOT/config"

        if [ ! -f "$USB_ROOT/config/portable.env" ]; then
            # No existing config - just copy
            echo " No existing portable.env. Copying from old version..."
            cp "$OLD_PATH/config/portable.env" "$USB_ROOT/config/portable.env"
        else
            # Both exist - smart merge
            echo " Both old and new portable.env exist. Smart merging..."
            echo " Old values will be added only if they don't exist in new config."
            echo ""

            NEW_CFG="$USB_ROOT/config/portable.env"
            OLD_CFG="$OLD_PATH/config/portable.env"
            MERGE_TMP="$USB_ROOT/config/portable.env.merged"

            # Start with new config as base
            cp "$NEW_CFG" "$MERGE_TMP"

            # Parse old config and add missing keys
            while IFS='=' read -r key value || [ -n "$key" ]; do
                # Skip empty lines and comments
                [ -z "$key" ] && continue
                [[ "$key" =~ ^[[:space:]]*# ]] && continue

                # Trim whitespace from key
                key=$(echo "$key" | xargs)

                # Check if this key exists in new config
                if ! grep -q "^${key}=" "$NEW_CFG" 2>/dev/null; then
                    echo -e " ${GREEN}Adding: ${key}=${value}${NC}"
                    echo "${key}=${value}" >> "$MERGE_TMP"
                else
                    echo " Keeping new: ${key}=${value}"
                fi
            done < "$OLD_CFG"

            # Replace original with merged version
            mv "$MERGE_TMP" "$NEW_CFG"
            echo ""
            echo -e " ${GREEN}Config merge done.${NC}"
        fi
    fi

    echo ""
fi

# --- Done ---
echo -e "${CYAN} =============================================${NC}"
echo -e "${CYAN}   Migration Complete!${NC}"
echo -e "${CYAN} =============================================${NC}"
echo ""
echo " Migration results:"
echo ""

NEW_MODEL_COUNT=$(ls -1d "$USB_ROOT/models"/*/ 2>/dev/null | wc -l | tr -d ' ')
echo -e " Models:  ${GREEN}${NEW_MODEL_COUNT}${NC} model directories"

NEW_DATA_COUNT=$(ls -1 "$USB_ROOT/data" 2>/dev/null | wc -l | tr -d ' ')
echo -e " Data:    ${GREEN}${NEW_DATA_COUNT}${NC} items in data directory"

if [ -f "$USB_ROOT/config/portable.env" ]; then
    echo -e " Config:  ${GREEN}portable.env exists${NC}"
fi

echo ""
echo -e " You can now run ${GREEN}launch.sh${NC} to start QwenPaw."
echo ""
