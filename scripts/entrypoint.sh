#!/bin/bash
set -e

# ==============================================================================
# CONFIGURATION
# ==============================================================================
DATA_DIR="/data"
STOCK_DIR="/opt/minecraft/community"  # Where your default configs live in the image
SERVER_JAR="/opt/minecraft/server.jar"
MEMORY="${MEMORY:-2G}"

echo "[Community] Starting Minecraft Server..."

# ==============================================================================
# STEP 1: EULA CHECK (Standard)
# ==============================================================================
if [[ "${EULA^^}" == "TRUE" ]]; then
    echo "eula=true" > "${DATA_DIR}/eula.txt"
    echo "[Community] EULA accepted via environment variable."
fi

# ==============================================================================
# STEP 2: SEED CONFIGS (One-Time Copy)
# ==============================================================================
# Logic: We loop through every file in the stock directory.
# If that filename does NOT exist in /data, we copy it.
# If it DOES exist, we skip it (preserving user edits).

echo "[Community] Checking for missing config files..."

# Ensure we actually have stock files to copy
if [ -d "$STOCK_DIR" ]; then
    # Iterate over files in the stock directory
    for src_file in "$STOCK_DIR"/*; do
        # Extract just the filename (e.g., "server.properties")
        filename=$(basename "$src_file")
        dest_file="${DATA_DIR}/${filename}"

        if [ ! -f "$dest_file" ]; then
            echo "[Community] Seeding default: ${filename}"
            cp "$src_file" "$dest_file"
        else
            echo "[Community] Skipped: ${filename} (User version exists)"
        fi
    done
else
    echo "[Community] WARNING: Stock directory $STOCK_DIR not found. Skipping seed."
fi

ONLINE_MODE="${ONLINE_MODE:-TRUE}"

if [[ "${ONLINE_MODE^^}" == "FALSE" ]]; then
    echo "[Entrypoint] WARNING: ONLINE_MODE is FALSE. Authentication disabled!"
    echo "[Entrypoint] Unverified users can connect. UUIDs will be generated offline."
    
    # Use sed to enforce online-mode=false
    # We use 's/^online-mode=.*/.../' to find the line starting with online-mode and replace it
    sed -i 's/^online-mode=.*/online-mode=false/' "${DATA_DIR}/server.properties"
else
    echo "[Entrypoint] Enforcing Online Mode (Secure)."
    sed -i 's/^online-mode=.*/online-mode=true/' "${DATA_DIR}/server.properties"
fi

# Ensure logs directory exists
mkdir -p "${DATA_DIR}/logs"

# Switch to data directory
cd "${DATA_DIR}"

# ==============================================================================
# STEP 3: LAUNCH
# ==============================================================================
echo "[Community] Launching with ${MEMORY} RAM."

exec java \
  -Xms"${MEMORY}" \
  -Xmx"${MEMORY}" \
  ${JVM_OPTS} \
  -jar "${SERVER_JAR}" \
  nogui