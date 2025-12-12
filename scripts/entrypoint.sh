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

DIAG_MODE="${DIAG_MODE:-TRUE}"

if [[ "${DIAG_MODE^^}" == "TRUE" ]]; then
    echo "[Entrypoint] WARNING: DIAG_MODE is TRUE. Nasty things may happen in production!"
    echo "[Entrypoint] Unverified users can connect. UUIDs will be generated offline. There is no throttle on connections."
    
    # Use sed to enforce online-mode=false
    # We use 's/^online-mode=.*/.../' to find the line starting with online-mode and replace it
    sed -i 's/^online-mode=.*/online-mode=false/' "${DATA_DIR}/server.properties"
    sed -i 's/connection-throttle: .*/connection-throttle: -1/' "${DATA_DIR}/bukkit.yml"
    mkdir -p "${DATA_DIR}/plugins"
    cp "/opt/minecraft/certified/plugins/prometheus-exporter.jar" "${DATA_DIR}/plugins/"
    PROMETHEUS_CONFIG="${DATA_DIR}/plugins/PrometheusExporter/config.yml"
    if [ ! -f "$PROMETHEUS_CONFIG" ]; then
        mkdir -p $(dirname "$PROMETHEUS_CONFIG")
        echo "host: 0.0.0.0" > "$PROMETHEUS_CONFIG"
        echo "port: 9090" >> "$PROMETHEUS_CONFIG"
        echo "enable_metrics: true" >> "$PROMETHEUS_CONFIG"
    fi
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