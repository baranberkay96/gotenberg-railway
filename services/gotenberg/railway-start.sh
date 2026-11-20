#!/bin/bash
# Railway start wrapper for Gotenberg: validates the deploy-form variables, then
# execs Gotenberg. Never exits because of a variable value (STANDARD 8.29).
set -u

log() { echo "railway-start: $*"; }
random_secret() { tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c 48; }

is_true() {
  case "$1" in 1|t|T|true|TRUE|True|yes|YES|Yes|on|ON|On) return 0 ;; *) return 1 ;; esac
}
is_bool() {
  case "$1" in 1|t|T|true|TRUE|True|yes|YES|Yes|on|ON|On|0|f|F|false|FALSE|False|no|NO|No|off|OFF|Off) return 0 ;; *) return 1 ;; esac
}

# Normalise a boolean variable to true/false, falling back to a default.
bool_var() {
  local name="$1" default="$2" value="${!1-}"
  if [ -z "$value" ]; then
    export "$name=$default"
  elif is_bool "$value"; then
    if is_true "$value"; then export "$name=true"; else export "$name=false"; fi
  else
    log "WARNING: $name='$value' is not true/false, using $default"
    export "$name=$default"
  fi
}

# Durations such as 30s, 2m, 1m30s, 500ms.
duration_var() {
  local name="$1" default="$2" value="${!1-}"
  if [ -z "$value" ]; then
    export "$name=$default"
  elif [[ "$value" =~ ^([0-9]+(ms|s|m|h))+$ ]]; then
    export "$name=$value"
  else
    log "WARNING: $name='$value' is not a duration like 90s or 2m, using $default"
    export "$name=$default"
  fi
}

# --- Port (public domain target and healthcheck) ---
if [[ "${PORT:-}" =~ ^[0-9]{1,5}$ ]] && [ "$PORT" -ge 1 ] && [ "$PORT" -le 65535 ]; then
  :
else
  [ -n "${PORT:-}" ] && log "WARNING: PORT='${PORT}' is not a valid port, using 3000"
  export PORT=3000
fi
unset API_PORT

# --- Flags that are exposed as template variables (Gotenberg exits on bad values) ---
duration_var API_TIMEOUT 90s
bool_var CHROMIUM_AUTO_START true
bool_var LIBREOFFICE_AUTO_START true
case "${LOG_LEVEL:-info}" in
  error|warn|info|debug) export LOG_LEVEL="${LOG_LEVEL:-info}" ;;
  ERROR|WARN|INFO|DEBUG) export LOG_LEVEL="$(echo "$LOG_LEVEL" | tr 'A-Z' 'a-z')" ;;
  *) log "WARNING: LOG_LEVEL='${LOG_LEVEL}' is not error/warn/info/debug, using info"; export LOG_LEVEL=info ;;
esac
if [ -n "${API_BODY_LIMIT:-}" ] && ! [[ "$API_BODY_LIMIT" =~ ^[0-9]+(\.[0-9]+)?[[:space:]]?([kKmMgGtT][iI]?)?[bB]?$ ]]; then
  log "WARNING: API_BODY_LIMIT='${API_BODY_LIMIT}' is not a size like 100MB, removing the limit"
  unset API_BODY_LIMIT
fi

# --- Basic authentication ---
bool_var API_ENABLE_BASIC_AUTH true
if [ "$API_ENABLE_BASIC_AUTH" = false ]; then
  if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
    log "WARNING: API_ENABLE_BASIC_AUTH=false is ignored because this service has a public domain (${RAILWAY_PUBLIC_DOMAIN})."
    log "         Remove the public domain first if Gotenberg should only be reachable on the private network without a password."
    export API_ENABLE_BASIC_AUTH=true
  else
    log "Basic authentication is OFF. Gotenberg has no public domain; only services in this Railway project can reach it."
  fi
fi

if [ "$API_ENABLE_BASIC_AUTH" = true ]; then
  user="${GOTENBERG_API_BASIC_AUTH_USERNAME:-}"
  if ! [[ "$user" =~ ^[A-Za-z0-9._@-]{1,64}$ ]]; then
    log "WARNING: GOTENBERG_API_BASIC_AUTH_USERNAME is empty or contains characters other than letters, digits and . _ @ -; using 'gotenberg'"
    user=gotenberg
  fi
  pass="${GOTENBERG_API_BASIC_AUTH_PASSWORD:-}"
  len=${#pass}
  if [ "$len" -lt 16 ] || [ "$len" -gt 256 ] || [[ "$pass" =~ [[:space:][:cntrl:]] ]]; then
    log "WARNING: GOTENBERG_API_BASIC_AUTH_PASSWORD is empty, shorter than 16 or longer than 256 characters, or contains spaces."
    log "         The API is LOCKED with a random password nobody knows (only /health stays open)."
    log "         Fix: set a password of 16-256 characters without spaces in the Variables tab and redeploy."
    pass="$(random_secret)"
  fi
  export GOTENBERG_API_BASIC_AUTH_USERNAME="$user" GOTENBERG_API_BASIC_AUTH_PASSWORD="$pass"
  log "Basic authentication is ON (user '${user}'); every route except /health requires it."
else
  unset GOTENBERG_API_BASIC_AUTH_USERNAME GOTENBERG_API_BASIC_AUTH_PASSWORD
fi
unset pass user

log "Gotenberg on port ${PORT}, request timeout ${API_TIMEOUT}, Chromium auto-start ${CHROMIUM_AUTO_START}, LibreOffice auto-start ${LIBREOFFICE_AUTO_START}"
exec gotenberg --api-port-from-env=PORT "$@"
