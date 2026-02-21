#!/bin/bash
set -euo pipefail

# ────────────────────────────────────────────────
# Configuration paths
# ────────────────────────────────────────────────

CONFIG="${VICOBOT_HOME}/config.json"

# ────────────────────────────────────────────────
# Auto-onboard if config doesn't exist yet
# ────────────────────────────────────────────────

if [ ! -f "${CONFIG}" ]; then
    echo "First run detected — running onboard..."
    /vicobot onboard
    echo "✅ Onboard complete. Config created at ${CONFIG}"
    echo ""
    echo "⚠️  Remember to configure API key and model."
    echo "   You can do this via environment variables or by mounting your own config."
    echo ""
fi

# ────────────────────────────────────────────────
# Apply environment variable overrides
# ────────────────────────────────────────────────

# ── Providers ───────────────────────────────────

[ -n "${OPENAI_API_KEY:-}" ] && {
    echo "→ Applying OPENAI_API_KEY"
    sed -i 's|"apiKey":\s*"[^"]*"|"apiKey": "'"${OPENAI_API_KEY}"'"|g' "${CONFIG}"
}

[ -n "${OPENAI_API_BASE:-}" ] && {
    echo "→ Applying OPENAI_API_BASE"
    sed -i 's|"apiBase":\s*"[^"]*"|"apiBase": "'"${OPENAI_API_BASE}"'"|g' "${CONFIG}"
}

# ── Agents defaults (model + tuning parameters) ──

# Support both VICOBOT_MODEL and DEFAULT_MODEL (last one wins)
MODEL_TO_USE="${VICOBOT_MODEL:-${DEFAULT_MODEL:-}}"
[ -n "${MODEL_TO_USE}" ] && {
    echo "→ Setting model = ${MODEL_TO_USE}"
    sed -i 's|"model":\s*"[^"]*"|"model": "'"${MODEL_TO_USE}"'"|g' "${CONFIG}"
}

# Support both VICOBOT_MAX_TOKENS and DEFAULT_MAX_TOKENS
MAX_TOKENS_TO_USE="${VICOBOT_MAX_TOKENS:-${DEFAULT_MAX_TOKENS:-}}"
[ -n "${MAX_TOKENS_TO_USE}" ] && {
    echo "→ Setting maxTokens = ${MAX_TOKENS_TO_USE}"
    sed -i 's/"maxTokens":\s*[0-9]\+/"maxTokens": '"${MAX_TOKENS_TO_USE}"'/g' "${CONFIG}"
}

# Support both VICOBOT_TEMPERATURE and DEFAULT_TEMPERATURE
TEMPERATURE_TO_USE="${VICOBOT_TEMPERATURE:-${DEFAULT_TEMPERATURE:-}}"
[ -n "${TEMPERATURE_TO_USE}" ] && {
    echo "→ Setting temperature = ${TEMPERATURE_TO_USE}"
    sed -i 's/"temperature":\s*[0-9.]\+/"temperature": '"${TEMPERATURE_TO_USE}"'/g' "${CONFIG}"
}

[ -n "${VICOBOT_WORKSPACE:-}" ] && {
    echo "→ Setting workspace = ${VICOBOT_WORKSPACE}"
    sed -i 's|"workspace":\s*"[^"]*"|"workspace": "'"${VICOBOT_WORKSPACE}"'"|g' "${CONFIG}"
}

[ -n "${VICOBOT_MAX_TOOL_ITERATIONS:-}" ] && {
    echo "→ Setting maxToolIterations = ${VICOBOT_MAX_TOOL_ITERATIONS}"
    sed -i 's/"maxToolIterations":\s*[0-9]\+/"maxToolIterations": '"${VICOBOT_MAX_TOOL_ITERATIONS}"'/g' "${CONFIG}"
}

[ -n "${VICOBOT_HEARTBEAT_INTERVAL:-}" ] && {
    echo "→ Setting heartbeatIntervalS = ${VICOBOT_HEARTBEAT_INTERVAL}"
    sed -i 's/"heartbeatIntervalS":\s*[0-9]\+/"heartbeatIntervalS": '"${VICOBOT_HEARTBEAT_INTERVAL}"'/g' "${CONFIG}"
}

# ── Telegram channel ─────────────────────────────

[ -n "${TELEGRAM_BOT_TOKEN:-}" ] && {
    echo "→ Enabling Telegram + applying token"
    sed -i 's/"enabled":\s*false/"enabled": true/' "${CONFIG}"
    sed -i 's|"token":\s*""|"token": "'"${TELEGRAM_BOT_TOKEN}"'"|g' "${CONFIG}"
}

[ -n "${TELEGRAM_ALLOW_FROM:-}" ] && {
    echo "→ Applying TELEGRAM_ALLOW_FROM"
    ALLOW_ARRAY=$(echo "${TELEGRAM_ALLOW_FROM}" | \
        tr -d '[:space:]' | \
        sed 's/,,*/,/g; s/^,//; s/,$//' | \
        awk -F',' '{for(i=1;i<=NF;i++) if($i!="") printf "\"%s\"%s", $i, (i<NF?",":"") }' | \
        sed 's/.*/[&]/; s/\[\]/[]/')
    
    [ -z "${ALLOW_ARRAY}" ] && ALLOW_ARRAY="[]"
    
    sed -i "s|\"allowFrom\":\s*\[\]|\"allowFrom\": ${ALLOW_ARRAY}|g" "${CONFIG}"
}

# ── Logging / debug flags (passed as env vars, not written to config) ──

# These are typically read directly by the application at runtime
# No sed needed — they are already in the environment when we exec

if [ -n "${VICOBOT_DEBUG:-}" ] || [ -n "${VICOBOT_LOG_LEVEL:-}" ]; then
    echo "→ Debug/logging overrides detected:"
    [ -n "${VICOBOT_DEBUG:-}" ]       && echo "  VICOBOT_DEBUG=${VICOBOT_DEBUG}"
    [ -n "${VICOBOT_LOG_LEVEL:-}" ]   && echo "  VICOBOT_LOG_LEVEL=${VICOBOT_LOG_LEVEL}"
fi

# ────────────────────────────────────────────────
# Start the application
# ────────────────────────────────────────────────

echo ""
echo "Starting vicobot $@..."
exec stdbuf -oL -eL /vicobot "$@"