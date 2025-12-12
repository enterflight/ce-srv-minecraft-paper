#!/bin/bash
set -e

# ==============================================================================
# CONFIGURATION
# ==============================================================================
DATA_DIR="/data"
SERVER_JAR="/opt/minecraft/server.jar"
MEMORY="${MEMORY:-2G}"

echo "[Community] Starting Minecraft Server..."

# ==============================================================================
# STEP 1: EULA CHECK
# ==============================================================================
# We keep this because it improves UX, but we don't force a hard exit 
# as aggressively as the Certified edition might in some contexts.
if [[ "${EULA^^}" == "TRUE" ]]; then
    echo "eula=true" > "${DATA_DIR}/eula.txt"
    echo "[Community] EULA accepted via environment variable."
fi

# ==============================================================================
# STEP 2: SETUP (Minimal)
# ==============================================================================
# We create the data directory, but we do NOT copy any config files.
# The server will generate default (vanilla) configs on first run.
mkdir -p "${DATA_DIR}/logs"

# Switch to data directory so the server writes files there
cd "${DATA_DIR}"

# ==============================================================================
# STEP 3: LAUNCH (Raw)
# ==============================================================================
# DIFFERENCE: No pre-tuned GC flags. No "Aikar's Flags".
# We only set memory. The user must supply their own tuning via JVM_OPTS.

echo "[Community] Launching with ${MEMORY} RAM."
echo "[Community] Note: No GC tuning applied. Use JVM_OPTS to add flags."

exec java \
  -Xms"${MEMORY}" \
  -Xmx"${MEMORY}" \
  ${JVM_OPTS} \
  -jar "${SERVER_JAR}" \
  nogui