#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/agentworkroom-common.sh
source "$(cd -- "$(dirname -- "$0")" && pwd)/agentworkroom-common.sh"

launchctl bootout "$(launchctl_domain)" "$AGENTWORKROOM_LAUNCHD_PLIST" >/dev/null 2>&1 || true
launchctl disable "$(launchctl_service_target)" >/dev/null 2>&1 || true

if command -v tmux >/dev/null 2>&1 && tmux_session_exists "$AGENTWORKROOM_TMUX_SESSION"; then
  info "Stopping tmux session $AGENTWORKROOM_TMUX_SESSION"
  tmux kill-session -t "$AGENTWORKROOM_TMUX_SESSION" >/dev/null 2>&1 || true
fi

if pid_is_running "$AGENTWORKROOM_GATEWAY_PIDFILE"; then
  pid=$(cat "$AGENTWORKROOM_GATEWAY_PIDFILE" 2>/dev/null || true)
  if [ -n "$pid" ]; then
    info "Stopping gateway PID $pid"
    kill "$pid" >/dev/null 2>&1 || true
    sleep 2
    if kill -0 "$pid" >/dev/null 2>&1; then
      warn "Gateway still alive, sending SIGKILL"
      kill -9 "$pid" >/dev/null 2>&1 || true
    fi
  fi
  rm -f "$AGENTWORKROOM_GATEWAY_PIDFILE"
else
  warn "Gateway PID file not running; cleaning stale PID file if present"
  rm -f "$AGENTWORKROOM_GATEWAY_PIDFILE"
fi

if port_is_listening "$AGENTWORKROOM_GATEWAY_PORT"; then
  while read -r pid; do
    [ -n "$pid" ] || continue
    info "Stopping listener on port $AGENTWORKROOM_GATEWAY_PORT (pid=$pid)"
    kill "$pid" >/dev/null 2>&1 || true
  done < <(lsof -tiTCP:"$AGENTWORKROOM_GATEWAY_PORT" -sTCP:LISTEN 2>/dev/null || true)
  sleep 1
  while read -r pid; do
    [ -n "$pid" ] || continue
    warn "Listener still alive on port $AGENTWORKROOM_GATEWAY_PORT; sending SIGKILL to pid=$pid"
    kill -9 "$pid" >/dev/null 2>&1 || true
  done < <(lsof -tiTCP:"$AGENTWORKROOM_GATEWAY_PORT" -sTCP:LISTEN 2>/dev/null || true)
fi

stop_compose_service "$AGENTWORKROOM_MANAGE_N8N" "${AGENTWORKROOM_N8N_COMPOSE:-}" "n8n"
stop_compose_service "$AGENTWORKROOM_MANAGE_HOME_ASSISTANT" "${AGENTWORKROOM_HOME_ASSISTANT_COMPOSE:-}" "Home Assistant"
stop_container_service "$AGENTWORKROOM_MANAGE_N8N" "${AGENTWORKROOM_N8N_CONTAINER:-}" "n8n"
stop_container_service "$AGENTWORKROOM_MANAGE_HOME_ASSISTANT" "${AGENTWORKROOM_HOME_ASSISTANT_CONTAINER:-}" "Home Assistant"
