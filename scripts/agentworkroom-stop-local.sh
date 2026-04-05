#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

if pid_is_running "$AGENTWORKROOM_GATEWAY_PIDFILE"; then
  pid=$(cat "$AGENTWORKROOM_GATEWAY_PIDFILE")
  info "Stopping gateway PID $pid"
  kill "$pid" >/dev/null 2>&1 || true
  sleep 2
  if kill -0 "$pid" >/dev/null 2>&1; then
    warn "Gateway still alive, sending SIGKILL"
    kill -9 "$pid" >/dev/null 2>&1 || true
  fi
  rm -f "$AGENTWORKROOM_GATEWAY_PIDFILE"
else
  warn "Gateway PID file not running; cleaning stale PID file if present"
  rm -f "$AGENTWORKROOM_GATEWAY_PIDFILE"
fi

stop_compose_service "$AGENTWORKROOM_MANAGE_N8N" "${AGENTWORKROOM_N8N_COMPOSE:-}" "n8n"
stop_compose_service "$AGENTWORKROOM_MANAGE_HOME_ASSISTANT" "${AGENTWORKROOM_HOME_ASSISTANT_COMPOSE:-}" "Home Assistant"
