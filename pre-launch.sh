#!/usr/bin/env bash
# packwiz pre-launch sync script (Mac/Linux)
# Fetched and executed from the modpack repo at launch time.

set -euo pipefail

PACK_URL="https://raw.githubusercontent.com/Broken7528/gurble-scratchpad/main/pack.toml"
BOOTSTRAP_VERSION="0.0.3"
BOOTSTRAP_URL="https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v${BOOTSTRAP_VERSION}/packwiz-installer-bootstrap.jar"

MC_DIR="${INST_MC_DIR:-.}"
JAVA_BIN="${INST_JAVA:-java}"
BOOTSTRAP_JAR="$MC_DIR/packwiz-installer-bootstrap.jar"

log() { echo "[packwiz-sync] $*"; }
die() { echo "[packwiz-sync] ERROR: $*" >&2; exit 1; }

if [[ ! -f "$BOOTSTRAP_JAR" ]]; then
    log "Downloading packwiz-installer-bootstrap v${BOOTSTRAP_VERSION}..."
    if command -v curl &>/dev/null; then
        curl -fsSL --location "$BOOTSTRAP_URL" -o "$BOOTSTRAP_JAR"
    elif command -v wget &>/dev/null; then
        wget -q "$BOOTSTRAP_URL" -O "$BOOTSTRAP_JAR"
    else
        die "Neither curl nor wget found. Cannot download bootstrap jar."
    fi
    log "Downloaded."
fi

log "Syncing modpack from: $PACK_URL"
log "Instance dir:         $MC_DIR"

cd "$MC_DIR"
"$JAVA_BIN" -Xmx256m -jar "$BOOTSTRAP_JAR" -g -s client "$PACK_URL"

log "Sync complete. Launching Minecraft."
