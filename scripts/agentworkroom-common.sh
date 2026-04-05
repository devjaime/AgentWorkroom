#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$repo_root"

if [ -f "$repo_root/config/local-stack.env" ]; then
  # shellcheck disable=SC1091
  source "$repo_root/config/local-stack.env"
fi

: "${OPENCLAW_HOME:=$HOME/.openclaw}"
: "${OPENCLAW_STATE_DIR:=$OPENCLAW_HOME}"
: "${OPENCLAW_CONFIG_PATH:=$OPENCLAW_HOME/openclaw.json}"
: "${AGENTWORKROOM_GATEWAY_HOST:=127.0.0.1}"
: "${AGENTWORKROOM_GATEWAY_PORT:=18789}"
: "${AGENTWORKROOM_GATEWAY_BIND:=loopback}"
: "${AGENTWORKROOM_GATEWAY_FORCE:=1}"
: "${AGENTWORKROOM_GATEWAY_LOG:=.agentworkroom/logs/gateway.log}"
: "${AGENTWORKROOM_GATEWAY_PIDFILE:=.agentworkroom/run/gateway.pid}"
: "${AGENTWORKROOM_BOOTSTRAP_BUILD:=1}"
: "${AGENTWORKROOM_BOOTSTRAP_UI_BUILD:=1}"
: "${AGENTWORKROOM_OLLAMA_URL:=http://127.0.0.1:11434}"
: "${AGENTWORKROOM_REQUIRED_TEXT_MODEL:=gemma4-openclaw:latest}"
: "${AGENTWORKROOM_REQUIRED_IMAGE_MODEL:=qwen3-vl:8b}"
: "${AGENTWORKROOM_HOME_ASSISTANT_URL:=http://127.0.0.1:8123}"
: "${AGENTWORKROOM_N8N_URL:=http://127.0.0.1:5678}"
: "${AGENTWORKROOM_MANAGE_HOME_ASSISTANT:=0}"
: "${AGENTWORKROOM_MANAGE_N8N:=0}"

mkdir -p "$(dirname -- "$AGENTWORKROOM_GATEWAY_LOG")" "$(dirname -- "$AGENTWORKROOM_GATEWAY_PIDFILE")"

info() { printf '[AgentWorkroom] %s\n' "$*"; }
warn() { printf '[AgentWorkroom] WARN: %s\n' "$*" >&2; }
fail() { printf '[AgentWorkroom] ERROR: %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing command: $1"
}

http_ok() {
  local url=$1
  curl -fsS -o /dev/null --max-time 5 "$url"
}

http_status_code() {
  local url=$1
  curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url" || printf '000'
}

ensure_compose_service() {
  local flag=$1
  local compose_file=$2
  local label=$3

  if [ "$flag" != "1" ]; then
    return 0
  fi
  [ -n "$compose_file" ] || fail "$label compose file is required when management is enabled"
  [ -f "$compose_file" ] || fail "$label compose file not found: $compose_file"
  require_cmd docker
  info "Starting $label via docker compose"
  docker compose -f "$compose_file" up -d
}

stop_compose_service() {
  local flag=$1
  local compose_file=$2
  local label=$3

  if [ "$flag" != "1" ] || [ -z "$compose_file" ] || [ ! -f "$compose_file" ]; then
    return 0
  fi
  require_cmd docker
  info "Stopping $label via docker compose"
  docker compose -f "$compose_file" stop
}

pid_is_running() {
  local pid_file=$1
  [ -f "$pid_file" ] || return 1
  local pid
  pid=$(cat "$pid_file")
  [ -n "$pid" ] || return 1
  kill -0 "$pid" >/dev/null 2>&1
}

port_listener_info() {
  local port=$1
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN 2>/dev/null | tail -n +2
  fi
}

port_is_listening() {
  local port=$1
  port_listener_info "$port" | grep -q .
}
