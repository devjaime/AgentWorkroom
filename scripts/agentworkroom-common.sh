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
: "${AGENTWORKROOM_GATEWAY_RUNTIME:=tmux}"
: "${AGENTWORKROOM_TMUX_SESSION:=agentworkroom-gateway}"
: "${AGENTWORKROOM_LAUNCHD_LABEL:=ai.agentworkroom.gateway}"
: "${AGENTWORKROOM_LAUNCHD_PLIST:=$HOME/Library/LaunchAgents/${AGENTWORKROOM_LAUNCHD_LABEL}.plist}"
: "${AGENTWORKROOM_WATCHDOG_INTERVAL_SECONDS:=60}"
: "${AGENTWORKROOM_WATCHDOG_LOG:=.agentworkroom/logs/watchdog.log}"
: "${AGENTWORKROOM_WATCHDOG_STATE:=.agentworkroom/state/watchdog-state}"
: "${AGENTWORKROOM_WATCHDOG_EVENTS:=.agentworkroom/state/watchdog-events.log}"
: "${AGENTWORKROOM_BOOTSTRAP_BUILD:=1}"
: "${AGENTWORKROOM_BOOTSTRAP_UI_BUILD:=1}"
: "${AGENTWORKROOM_OLLAMA_URL:=http://127.0.0.1:11434}"
: "${AGENTWORKROOM_REQUIRED_TEXT_MODEL:=gemma4-openclaw:latest}"
: "${AGENTWORKROOM_REQUIRED_IMAGE_MODEL:=qwen3-vl:8b}"
: "${AGENTWORKROOM_HOME_ASSISTANT_URL:=http://127.0.0.1:8123}"
: "${AGENTWORKROOM_N8N_URL:=http://127.0.0.1:5678}"
: "${AGENTWORKROOM_MANAGE_HOME_ASSISTANT:=0}"
: "${AGENTWORKROOM_MANAGE_N8N:=0}"
: "${AGENTWORKROOM_HOME_ASSISTANT_COMPOSE:=}"
: "${AGENTWORKROOM_N8N_COMPOSE:=}"
: "${AGENTWORKROOM_HOME_ASSISTANT_CONTAINER:=}"
: "${AGENTWORKROOM_N8N_CONTAINER:=}"

mkdir -p \
  "$(dirname -- "$AGENTWORKROOM_GATEWAY_LOG")" \
  "$(dirname -- "$AGENTWORKROOM_GATEWAY_PIDFILE")" \
  "$(dirname -- "$AGENTWORKROOM_WATCHDOG_LOG")" \
  "$(dirname -- "$AGENTWORKROOM_WATCHDOG_STATE")"

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
  local code
  if code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null); then
    printf '%s' "$code"
  else
    printf '000'
  fi
}

gateway_http_status_is_healthy() {
  local code=$1
  case "$code" in
    2*|3*|401|403)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

ensure_compose_service() {
  local flag=$1
  local compose_file=$2
  local label=$3

  if [ "$flag" != "1" ]; then
    return 0
  fi
  if [ -z "$compose_file" ]; then
    return 0
  fi
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

container_exists() {
  local name=$1
  [ -n "$name" ] || return 1
  docker container inspect "$name" >/dev/null 2>&1
}

container_is_running() {
  local name=$1
  [ -n "$name" ] || return 1
  [ "$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null || true)" = "true" ]
}

ensure_container_service() {
  local flag=$1
  local container_name=$2
  local label=$3

  if [ "$flag" != "1" ] || [ -z "$container_name" ]; then
    return 0
  fi
  require_cmd docker
  if ! container_exists "$container_name"; then
    fail "$label container not found: $container_name"
  fi
  if container_is_running "$container_name"; then
    info "$label container already running ($container_name)"
    return 0
  fi
  info "Starting $label container ($container_name)"
  docker start "$container_name" >/dev/null
}

stop_container_service() {
  local flag=$1
  local container_name=$2
  local label=$3

  if [ "$flag" != "1" ] || [ -z "$container_name" ]; then
    return 0
  fi
  require_cmd docker
  if ! container_exists "$container_name"; then
    warn "$label container not found: $container_name"
    return 0
  fi
  if ! container_is_running "$container_name"; then
    info "$label container already stopped ($container_name)"
    return 0
  fi
  info "Stopping $label container ($container_name)"
  docker stop "$container_name" >/dev/null
}

has_a2ui_bundle_or_sources() {
  local bundle="$repo_root/src/canvas-host/a2ui/a2ui.bundle.js"
  local renderer="$repo_root/vendor/a2ui/renderers/lit"
  local app_dir="$repo_root/apps/shared/OpenClawKit/Tools/CanvasA2UI"
  [ -f "$bundle" ] || { [ -d "$renderer" ] && [ -d "$app_dir" ]; }
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

launchctl_domain() {
  printf 'gui/%s' "$(id -u)"
}

launchctl_service_target() {
  printf '%s/%s' "$(launchctl_domain)" "$AGENTWORKROOM_LAUNCHD_LABEL"
}

launchagent_is_loaded() {
  launchctl print "$(launchctl_service_target)" >/dev/null 2>&1
}

tmux_session_exists() {
  local session_name=$1
  tmux has-session -t "$session_name" >/dev/null 2>&1
}

listener_pid() {
  local port=$1
  if command -v lsof >/dev/null 2>&1; then
    lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null | head -n 1
  fi
}

process_elapsed() {
  local pid=$1
  [ -n "$pid" ] || return 1
  ps -p "$pid" -o etime= 2>/dev/null | awk '{$1=$1; print}'
}

current_iso_timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

record_watchdog_event() {
  local level=$1
  local action=$2
  local message=$3
  local now
  now=$(current_iso_timestamp)
  printf '%s\t%s\t%s\t%s\n' "$now" "$level" "$action" "$message" >> "$AGENTWORKROOM_WATCHDOG_EVENTS"
}

set_watchdog_state() {
  local state=$1
  printf '%s\n' "$state" > "$AGENTWORKROOM_WATCHDOG_STATE"
}

get_watchdog_state() {
  if [ -f "$AGENTWORKROOM_WATCHDOG_STATE" ]; then
    cat "$AGENTWORKROOM_WATCHDOG_STATE"
  else
    printf 'unknown'
  fi
}

repo_root_is_in_protected_user_dir() {
  case "$repo_root" in
    "$HOME/Desktop"/*|"$HOME/Documents"/*|"$HOME/Downloads"/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}
